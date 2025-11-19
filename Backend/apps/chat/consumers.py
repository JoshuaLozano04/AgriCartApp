"""
WebSocket consumer for real-time chat messaging.
"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from utils.jwt_auth import verify_token
from utils.mongodb_service import MongoDBService
from utils.notification_service import NotificationService


class ChatConsumer(AsyncWebsocketConsumer):
    """WebSocket consumer for handling real-time chat messages."""

    async def connect(self):
        """Handle WebSocket connection."""
        # Get conversation_id from URL
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        
        # Get token from query string
        query_string = self.scope.get('query_string', b'').decode()
        token = None
        if 'token=' in query_string:
            token = query_string.split('token=')[1].split('&')[0]
        
        # Authenticate user via JWT token
        if not token:
            await self.close(code=4000)  # Custom code: Authentication failed
            return
        
        try:
            payload = verify_token(token)
            if not payload:
                await self.close(code=4000)
                return
            
            self.user_id = payload.get('user_id')
            if not self.user_id:
                await self.close(code=4000)
                return
            
            # Verify user is part of this conversation
            if not await self.verify_conversation_access():
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
        message_text = data.get('message', '').strip()
        receiver_id = data.get('receiver_id')
        
        if not message_text:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Message cannot be empty'
            }))
            return
        
        if not receiver_id:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Receiver ID is required'
            }))
            return
        
        # Save message to MongoDB
        message_id = await self.save_message(message_text, receiver_id)
        
        if not message_id:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Failed to save message'
            }))
            return
        
        # Get saved message
        message = await self.get_message(message_id)
        
        # Send message to room group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': message
            }
        )
        
        # Send confirmation to sender
        await self.send(text_data=json.dumps({
            'type': 'message_sent',
            'message_id': message_id,
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
        conversation = MongoDBService.get_document('conversations', self.conversation_id)
        if not conversation:
            return False
        
        user1_id = conversation.get('user1_id')
        user2_id = conversation.get('user2_id')
        
        return self.user_id in [user1_id, user2_id]

    @database_sync_to_async
    def save_message(self, message_text, receiver_id):
        """Save message to MongoDB."""
        message_data = {
            'conversation_id': self.conversation_id,
            'sender_id': self.user_id,
            'receiver_id': receiver_id,
            'message': message_text,
            'is_read': False,
            'created_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        }
        
        try:
            message_id = MongoDBService.create_document('messages', message_data)
            
            # Update conversation with last message
            MongoDBService.update_document('conversations', self.conversation_id, {
                'last_message': message_text,
                'last_message_at': 'SERVER_TIMESTAMP',
                'updated_at': 'SERVER_TIMESTAMP'
            })

            # Persist a notification for receiver and attempt to send unread
            try:
                NotificationService().create_notification(
                    user_id=receiver_id,
                    notification_type='chat_message',
                    title='New Message',
                    body=message_text,
                    data={'thread_id': self.conversation_id}
                )
                NotificationService().send_unread_for_user(receiver_id)
            except Exception as e:
                print(f'Notification error (chat ws): {e}')
            
            return message_id
        except Exception as e:
            print(f'Error saving message: {e}')
            return None

    @database_sync_to_async
    def get_message(self, message_id):
        """Get message from MongoDB."""
        return MongoDBService.get_document('messages', message_id)

    @database_sync_to_async
    def mark_message_as_read(self, message_id):
        """Mark message as read."""
        MongoDBService.update_document('messages', message_id, {
            'is_read': True,
            'read_at': 'SERVER_TIMESTAMP'
        })

