"""
WebSocket consumer for real-time chat messaging.
"""
import json
import uuid
from datetime import datetime, timezone
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from utils.jwt_auth import verify_token
from utils.mongodb_service import MongoDBService
from utils.notification_service import NotificationService


class ChatConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for handling real-time chat messages."""

    async def connect(self):
        """Handle WebSocket connection."""
        print('=' * 80)
        print('ChatConsumer: CONNECT METHOD CALLED')
        
        # Get conversation_id from URL
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        print(f'ChatConsumer: Conversation ID: {self.conversation_id}')
        
        # Get user from scope (populated by TokenAuthMiddleware)
        user = self.scope.get('user')
        print(f'ChatConsumer: User from scope: {user}, Type: {type(user) if user else None}')
        
        if not user or not hasattr(user, 'user_id'):
            print(f'ChatConsumer: No user in scope for conversation {self.conversation_id}')
            await self.close(code=4000)  # Custom code: Authentication failed
            return
        
        try:
            self.user_id = user.user_id
            print(f'ChatConsumer: User {self.user_id} connecting to conversation {self.conversation_id}')
            
            # Verify user is part of this conversation
            if not await self.verify_conversation_access():
                print(f'ChatConsumer: User {self.user_id} not authorized for conversation {self.conversation_id}')
                await self.close(code=4002)  # Custom code: Not authorized
                return
            
            # Join room group
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            
            await self.accept()
            
            # Send connection confirmation
            await self.send(text_data=json.dumps({
                'type': 'connection',
                'message': 'Connected to chat',
                'conversation_id': self.conversation_id
            }))
            
        except Exception as e:
            print(f'Error connecting WebSocket: {e}')
            await self.close(code=4000)

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """Receive message from WebSocket."""
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'chat_message')
            
            if message_type == 'chat_message':
                await self.handle_chat_message(data)
            elif message_type == 'typing':
                await self.handle_typing_indicator(data)
            elif message_type == 'read_receipt':
                await self.handle_read_receipt(data)
            else:
                await self.send(text_data=json.dumps({
                    'type': 'error',
                    'message': f'Unknown message type: {message_type}'
                }))
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Invalid JSON format'
            }))
        except Exception as e:
            print(f'Error receiving message: {e}')
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Error processing message'
            }))

    async def handle_chat_message(self, data):
        """Handle incoming chat message."""
        print(f'ChatConsumer: handle_chat_message called with data: {data}')
        message_text = data.get('message', '').strip()
        receiver_id = data.get('receiver_id')
        temp_id = data.get('temp_id')  # Client-generated temporary ID for optimistic UI
        
        print(f'ChatConsumer: message_text={message_text}, receiver_id={receiver_id}, temp_id={temp_id}')
        
        if not message_text:
            print(f'ChatConsumer: Empty message, rejecting')
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Message cannot be empty',
                'temp_id': temp_id
            }))
            return
        
        if not receiver_id:
            print(f'ChatConsumer: No receiver_id, rejecting')
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Receiver ID is required',
                'temp_id': temp_id
            }))
            return
        
        # Generate server message_id
        message_id = str(uuid.uuid4())
        print(f'ChatConsumer: Generated message_id={message_id}')
        
        # Save message to MongoDB
        print(f'ChatConsumer: Calling save_message...')
        success = await self.save_message(message_id, message_text, receiver_id)
        print(f'ChatConsumer: save_message returned: {success}')
        
        if not success:
            print(f'ChatConsumer: Failed to save message, sending error')
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Failed to save message',
                'temp_id': temp_id
            }))
            return
        
        # Get saved message with timestamp
        print(f'ChatConsumer: Getting message from DB...')
        message = await self.get_message(message_id)
        print(f'ChatConsumer: Retrieved message: {message}')
        
        # Send message to room group (all participants)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': message
            }
        )
        
        # Send acknowledgement to sender with temp_id mapping
        await self.send(text_data=json.dumps({
            'type': 'message_sent',
            'message_id': message_id,
            'temp_id': temp_id,
            'timestamp': message.get('created_at'),
            'status': 'success'
        }))

    async def handle_typing_indicator(self, data):
        """Handle typing indicator."""
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing',
                'user_id': self.user_id,
                'is_typing': data.get('is_typing', False)
            }
        )

    async def handle_read_receipt(self, data):
        """Handle read receipt."""
        message_id = data.get('message_id')
        if message_id:
            await self.mark_message_as_read(message_id)
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'read_receipt',
                    'message_id': message_id,
                    'user_id': self.user_id
                }
            )

    # Handler methods called by channel_layer.group_send
    async def chat_message(self, event):
        """Send chat message to WebSocket."""
        message = event['message']
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': message
        }))

    async def typing(self, event):
        """Send typing indicator to WebSocket."""
        await self.send(text_data=json.dumps({
            'type': 'typing',
            'user_id': event['user_id'],
            'is_typing': event['is_typing']
        }))

    async def read_receipt(self, event):
        """Send read receipt to WebSocket."""
        await self.send(text_data=json.dumps({
            'type': 'read_receipt',
            'message_id': event['message_id'],
            'user_id': event['user_id']
        }))

    # Database helper methods
    @database_sync_to_async
    def verify_conversation_access(self):
        """Verify user is part of the conversation."""
        # Query by conversation_id field (UUID string), not _id (ObjectId)
        try:
            conversations = MongoDBService.query_collection(
                'conversations',
                filters=[('conversation_id', '==', self.conversation_id)],
                limit=1
            )
            
            print(f'ChatConsumer: Found {len(conversations)} conversations for {self.conversation_id}')
            
            if not conversations:
                print(f'ChatConsumer: No conversation found with id {self.conversation_id}')
                return False
            
            conversation = conversations[0]
            user1_id = conversation.get('user1_id')
            user2_id = conversation.get('user2_id')
            
            print(f'ChatConsumer: Conversation participants: {user1_id}, {user2_id}. Current user: {self.user_id}')
            
            has_access = self.user_id in [user1_id, user2_id]
            print(f'ChatConsumer: Access granted: {has_access}')
            return has_access
        except Exception as e:
            print(f'ChatConsumer: Error verifying access: {e}')
            import traceback
            traceback.print_exc()
            return False

    @database_sync_to_async
    def save_message(self, message_id, message_text, receiver_id):
        """Save message to MongoDB with server-generated message_id."""
        print(f'ChatConsumer.save_message: Starting save - message_id={message_id}')
        now = datetime.now(timezone.utc)
        
        message_data = {
            'message_id': message_id,
            'conversation_id': self.conversation_id,
            'sender_id': self.user_id,
            'receiver_id': receiver_id,
            'message': message_text,
            'is_read': False,
            'read_at': None,
            'created_at': now,
            'updated_at': now
        }
        
        print(f'ChatConsumer.save_message: message_data={message_data}')
        
        try:
            # Create document with custom ID (message_id)
            print(f'ChatConsumer.save_message: Calling MongoDBService.create_document...')
            MongoDBService.create_document('messages', message_data, message_id)
            print(f'ChatConsumer.save_message: Document created successfully')
            
            # Update conversation with last message - find by conversation_id first
            conversations = MongoDBService.query_collection(
                'conversations',
                filters=[('conversation_id', '==', self.conversation_id)],
                limit=1
            )
            if conversations:
                conv_doc_id = conversations[0].get('_id')
                if conv_doc_id:
                    MongoDBService.update_document('conversations', str(conv_doc_id), {
                        'last_message': message_text,
                        'last_message_at': now,
                        'updated_at': now
                    })

            # Send push notification to receiver if not connected
            try:
                NotificationService().create_notification(
                    user_id=receiver_id,
                    notification_type='chat_message',
                    title='New Message',
                    body=message_text[:100],  # Truncate long messages
                    data={'conversation_id': self.conversation_id, 'message_id': message_id}
                )
                NotificationService().send_unread_for_user(receiver_id)
            except Exception as e:
                print(f'Notification error (chat ws): {e}')
            
            return True
        except Exception as e:
            print(f'Error saving message: {e}')
            return False

    @database_sync_to_async
    def get_message(self, message_id):
        """Get message from MongoDB by message_id field."""
        messages = MongoDBService.query_collection(
            'messages',
            filters=[('message_id', '==', message_id)],
            limit=1
        )
        return messages[0] if messages else None

    @database_sync_to_async
    def mark_message_as_read(self, message_id):
        """Mark message as read by message_id field."""
        # Find the message first
        messages = MongoDBService.query_collection(
            'messages',
            filters=[('message_id', '==', message_id)],
            limit=1
        )
        if messages:
            # Update using the document's _id
            doc_id = messages[0].get('_id')
            if doc_id:
                MongoDBService.update_document('messages', str(doc_id), {
                    'is_read': True,
                    'read_at': datetime.now(timezone.utc)
                })

