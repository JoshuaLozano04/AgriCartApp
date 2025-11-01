"""
Chat/messaging views.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from utils.firebase_service import FirebaseService
from firebase_admin import firestore
import uuid


@api_view(['POST'])
def send_message(request):
    """Send a message."""
    sender_id = request.data.get('sender_id')
    receiver_id = request.data.get('receiver_id')
    message_text = request.data.get('message')
    
    if not sender_id or not receiver_id or not message_text:
        return Response({
            'success': False,
            'message': 'sender_id, receiver_id, and message are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        message_id = str(uuid.uuid4())
        message_data = {
            'message_id': message_id,
            'sender_id': sender_id,
            'receiver_id': receiver_id,
            'message': message_text,
            'read': False,
            'created_at': firestore.SERVER_TIMESTAMP
        }
        
        FirebaseService.create_document('messages', message_data, message_id)
        
        return Response({
            'success': True,
            'message_id': message_id
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to send message: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_conversation(request):
    """Get conversation between two users."""
    user1_id = request.query_params.get('user1_id')
    user2_id = request.query_params.get('user2_id')
    
    if not user1_id or not user2_id:
        return Response({
            'success': False,
            'message': 'user1_id and user2_id are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        messages = []
        # Get messages from user1 to user2
        filters1 = [
            ('sender_id', '==', user1_id),
            ('receiver_id', '==', user2_id)
        ]
        results1 = FirebaseService.query_collection('messages', filters=filters1)
        for doc in results1:
            msg_data = doc.to_dict()
            if 'created_at' in msg_data:
                msg_data['created_at'] = msg_data['created_at'].isoformat() if hasattr(msg_data['created_at'], 'isoformat') else str(msg_data['created_at'])
            messages.append(msg_data)
        
        # Get messages from user2 to user1
        filters2 = [
            ('sender_id', '==', user2_id),
            ('receiver_id', '==', user1_id)
        ]
        results2 = FirebaseService.query_collection('messages', filters=filters2)
        for doc in results2:
            msg_data = doc.to_dict()
            if 'created_at' in msg_data:
                msg_data['created_at'] = msg_data['created_at'].isoformat() if hasattr(msg_data['created_at'], 'isoformat') else str(msg_data['created_at'])
            messages.append(msg_data)
        
        # Sort by created_at
        messages.sort(key=lambda x: x.get('created_at', ''))
        
        return Response({
            'success': True,
            'messages': messages
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve messages: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
