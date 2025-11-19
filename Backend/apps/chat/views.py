"""
Chat/messaging REST API views for conversation management.
Real-time messaging is handled via WebSocket in consumers.py
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from utils.mongodb_service import MongoDBService
from utils.fcm_service import FCMService
from utils.notification_service import NotificationService
import uuid


@api_view(['POST'])
def create_or_get_conversation(request):
    """Create or get conversation between two users."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user1_id = request.user.user_id
    user2_id = request.data.get('user2_id')
    
    if not user2_id:
        return Response({
            'success': False,
            'message': 'user2_id is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    if user1_id == user2_id:
        return Response({
            'success': False,
            'message': 'Cannot create conversation with yourself'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Check if conversation already exists (either direction)
        conversation1 = MongoDBService.query_collection(
            'conversations',
            filters=[
                ('user1_id', '==', user1_id),
                ('user2_id', '==', user2_id)
            ],
            limit=1
        )
        
        conversation2 = MongoDBService.query_collection(
            'conversations',
            filters=[
                ('user1_id', '==', user2_id),
                ('user2_id', '==', user1_id)
            ],
            limit=1
        )
        
        if conversation1:
            conversation = conversation1[0]
        elif conversation2:
            conversation = conversation2[0]
        else:
            # Create new conversation
            conversation_id = str(uuid.uuid4())
            conversation_data = {
                'conversation_id': conversation_id,
                'user1_id': user1_id,
                'user2_id': user2_id,
                'last_message': '',
                'last_message_at': 'SERVER_TIMESTAMP',
                'created_at': 'SERVER_TIMESTAMP',
                'updated_at': 'SERVER_TIMESTAMP'
            }
            MongoDBService.create_document('conversations', conversation_data, conversation_id)
            conversation = conversation_data
        
        # Get other user info
        other_user_id = user2_id if conversation['user1_id'] == user1_id else conversation['user1_id']
        other_user = MongoDBService.get_document('users', other_user_id)
        if other_user:
            other_user.pop('password_hash', None)
        
        return Response({
            'success': True,
            'conversation_id': conversation['conversation_id'],
            'conversation': {
                **conversation,
                'other_user': other_user
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to create/get conversation: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_user_conversations(request):
    """Get all conversations for the current user."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    
    try:
        # Get conversations where user is user1
        conversations1 = MongoDBService.query_collection(
            'conversations',
            filters=[('user1_id', '==', user_id)],
            order_by='-last_message_at'
        )
        
        # Get conversations where user is user2
        conversations2 = MongoDBService.query_collection(
            'conversations',
            filters=[('user2_id', '==', user_id)],
            order_by='-last_message_at'
        )
        
        all_conversations = conversations1 + conversations2
        
        # Enrich with other user info and unread count
        enriched_conversations = []
        for conv in all_conversations:
            other_user_id = conv['user2_id'] if conv['user1_id'] == user_id else conv['user1_id']
            other_user = MongoDBService.get_document('users', other_user_id)
            if other_user:
                other_user.pop('password_hash', None)
            
            # Count unread messages
            unread_count = MongoDBService.count_documents('messages', [
                ('conversation_id', '==', conv['conversation_id']),
                ('receiver_id', '==', user_id),
                ('is_read', '==', False)
            ])
            
            enriched_conversations.append({
                'conversation_id': conv['conversation_id'],
                'other_user': other_user,
                'last_message': conv.get('last_message', ''),
                'last_message_at': conv.get('last_message_at', ''),
                'unread_count': unread_count,
                'created_at': conv.get('created_at', '')
            })
        
        return Response({
            'success': True,
            'conversations': enriched_conversations
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve conversations: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_conversation_messages(request, conversation_id):
    """Get all messages in a conversation."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    
    try:
        # Verify user is part of conversation
        conversation = MongoDBService.get_document('conversations', conversation_id)
        if not conversation:
            return Response({
                'success': False,
                'message': 'Conversation not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        if conversation['user1_id'] != user_id and conversation['user2_id'] != user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Not part of this conversation'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Get messages
        messages = MongoDBService.query_collection(
            'messages',
            filters=[('conversation_id', '==', conversation_id)],
            order_by='created_at'
        )
        
        return Response({
            'success': True,
            'messages': messages
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve messages: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
def mark_conversation_read(request, conversation_id):
    """Mark all messages in a conversation as read."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    
    try:
        # Verify user is part of conversation
        conversation = MongoDBService.get_document('conversations', conversation_id)
        if not conversation:
            return Response({
                'success': False,
                'message': 'Conversation not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        if conversation['user1_id'] != user_id and conversation['user2_id'] != user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Not part of this conversation'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Mark all unread messages as read
        updated_count = MongoDBService.update_many(
            'messages',
            {
                'conversation_id': conversation_id,
                'receiver_id': user_id,
                'is_read': False
            },
            {
                'is_read': True,
                'read_at': 'SERVER_TIMESTAMP'
            }
        )
        
        return Response({
            'success': True,
            'message': f'Marked {updated_count} messages as read'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to mark messages as read: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def send_message_rest(request):
    """Send a message via REST API (fallback when WebSocket is not available)."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    sender_id = request.user.user_id
    conversation_id = request.data.get('conversation_id')
    receiver_id = request.data.get('receiver_id')
    message_text = request.data.get('message', '').strip()
    
    if not message_text:
        return Response({
            'success': False,
            'message': 'Message cannot be empty'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # If conversation_id provided, use it; otherwise create/get conversation
        if conversation_id:
            conversation = MongoDBService.get_document('conversations', conversation_id)
            if not conversation:
                return Response({
                    'success': False,
                    'message': 'Conversation not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            if conversation['user1_id'] != sender_id and conversation['user2_id'] != sender_id:
                return Response({
                    'success': False,
                    'message': 'Unauthorized: Not part of this conversation'
                }, status=status.HTTP_403_FORBIDDEN)
            
            receiver_id = conversation['user2_id'] if conversation['user1_id'] == sender_id else conversation['user1_id']
        elif receiver_id:
            # Get or create conversation
            conversation = None
            conv1 = MongoDBService.query_collection(
                'conversations',
                filters=[
                    ('user1_id', '==', sender_id),
                    ('user2_id', '==', receiver_id)
                ],
                limit=1
            )
            conv2 = MongoDBService.query_collection(
                'conversations',
                filters=[
                    ('user1_id', '==', receiver_id),
                    ('user2_id', '==', sender_id)
                ],
                limit=1
            )
            
            if conv1:
                conversation_id = conv1[0]['conversation_id']
            elif conv2:
                conversation_id = conv2[0]['conversation_id']
            else:
                # Create new conversation
                conversation_id = str(uuid.uuid4())
                conversation_data = {
                    'conversation_id': conversation_id,
                    'user1_id': sender_id,
                    'user2_id': receiver_id,
                    'last_message': message_text,
                    'last_message_at': 'SERVER_TIMESTAMP',
                    'created_at': 'SERVER_TIMESTAMP',
                    'updated_at': 'SERVER_TIMESTAMP'
                }
                MongoDBService.create_document('conversations', conversation_data, conversation_id)
        else:
            return Response({
                'success': False,
                'message': 'Either conversation_id or receiver_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create message
        message_id = str(uuid.uuid4())
        message_data = {
            'message_id': message_id,
            'conversation_id': conversation_id,
            'sender_id': sender_id,
            'receiver_id': receiver_id,
            'message': message_text,
            'is_read': False,
            'created_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        }
        
        MongoDBService.create_document('messages', message_data, message_id)
        
        # Update conversation
        MongoDBService.update_document('conversations', conversation_id, {
            'last_message': message_text,
            'last_message_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        })
        
        # Create notification and push if unread
        try:
            NotificationService().create_notification(
                user_id=receiver_id,
                notification_type='chat_message',
                title='New Message',
                body=message_text,
                data={'thread_id': conversation_id}
            )
            NotificationService().send_unread_for_user(receiver_id)
        except Exception:
            pass
        
        return Response({
            'success': True,
            'message_id': message_id,
            'conversation_id': conversation_id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to send message: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
