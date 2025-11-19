"""
MongoDB document schemas for chat/messaging collections.
Defines structure for conversations and messages.
"""
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any


class ConversationSchema:
    """Schema for conversation documents in 'conversations' collection."""
    
    @staticmethod
    def create(user1_id: str, user2_id: str, conversation_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Create a new conversation document.
        
        Args:
            user1_id: First user's ID
            user2_id: Second user's ID
            conversation_id: Optional custom conversation ID (UUID generated if not provided)
            
        Returns:
            Conversation document dictionary
        """
        if not conversation_id:
            conversation_id = str(uuid.uuid4())
        
        return {
            'conversation_id': conversation_id,
            'user1_id': user1_id,
            'user2_id': user2_id,
            'participants': [user1_id, user2_id],  # For easier querying
            'last_message': '',
            'last_message_at': datetime.now(timezone.utc),
            'created_at': datetime.now(timezone.utc),
            'updated_at': datetime.now(timezone.utc)
        }
    
    @staticmethod
    def get_required_indexes():
        """
        Get list of required indexes for conversations collection.
        
        Returns:
            List of tuples: (field_name, direction, unique_flag)
        """
        return [
            ('conversation_id', 1, True),  # Unique index on conversation_id
            ('participants', 1, False),    # Index on participants array
            ('last_message_at', -1, False) # Descending index for sorting
        ]


class MessageSchema:
    """Schema for message documents in 'messages' collection."""
    
    @staticmethod
    def create(
        conversation_id: str,
        sender_id: str,
        receiver_id: str,
        message: str,
        message_id: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Create a new message document.
        
        Args:
            conversation_id: ID of the conversation
            sender_id: Sender user ID
            receiver_id: Receiver user ID
            message: Message text content
            message_id: Optional custom message ID (UUID generated if not provided)
            metadata: Optional metadata dictionary (e.g., attachments, message type)
            
        Returns:
            Message document dictionary
        """
        if not message_id:
            message_id = str(uuid.uuid4())
        
        return {
            'message_id': message_id,
            'conversation_id': conversation_id,
            'sender_id': sender_id,
            'receiver_id': receiver_id,
            'message': message,
            'metadata': metadata or {},
            'is_read': False,
            'read_at': None,
            'created_at': datetime.now(timezone.utc),
            'updated_at': datetime.now(timezone.utc)
        }
    
    @staticmethod
    def get_required_indexes():
        """
        Get list of required indexes for messages collection.
        
        Returns:
            List of tuples: (field_name, direction, unique_flag)
        """
        return [
            ('message_id', 1, True),        # Unique index on message_id
            ('conversation_id', 1, False),  # Index for conversation queries
            ('created_at', 1, False),       # Index for sorting
            ('receiver_id', 1, False),      # Index for unread queries
            ('is_read', 1, False)           # Index for unread filtering
        ]


def ensure_indexes(mongodb_service):
    """
    Ensure all required indexes exist in MongoDB collections.
    
    Args:
        mongodb_service: Instance of MongoDBService
    """
    # Create indexes for conversations
    conversations_collection = mongodb_service.get_collection('conversations')
    for field, direction, unique in ConversationSchema.get_required_indexes():
        try:
            conversations_collection.create_index(
                [(field, direction)],
                unique=unique,
                background=True
            )
            print(f'Created index on conversations.{field}')
        except Exception as e:
            print(f'Index on conversations.{field} already exists or error: {e}')
    
    # Create indexes for messages
    messages_collection = mongodb_service.get_collection('messages')
    for field, direction, unique in MessageSchema.get_required_indexes():
        try:
            messages_collection.create_index(
                [(field, direction)],
                unique=unique,
                background=True
            )
            print(f'Created index on messages.{field}')
        except Exception as e:
            print(f'Index on messages.{field} already exists or error: {e}')
