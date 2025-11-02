"""
Firebase Cloud Messaging service for push notifications.
Uses Firebase Admin SDK with V1 API (recommended approach).
"""
from firebase_admin import messaging
from django.conf import settings
from utils.firebase_service import FirebaseService


class FCMService:
    """Service for sending push notifications via FCM using V1 API."""
    
    def __init__(self):
        # Initialize Firebase Admin SDK if not already initialized
        FirebaseService.initialize()
    
    def send_notification(self, device_token: str, title: str, body: str, data: dict = None):
        """
        Send push notification to a device using FCM V1 API.
        
        Args:
            device_token: FCM device token
            title: Notification title
            body: Notification body
            data: Optional data payload (dict)
            
        Returns:
            True if successful, False otherwise
        """
        if not device_token:
            return False
        
        try:
            # Create notification message
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                token=device_token,
            )
            
            # Add data payload if provided
            if data:
                message.data = {str(k): str(v) for k, v in data.items()}
            
            # Send the message
            response = messaging.send(message)
            print(f'Successfully sent message: {response}')
            return True
        except Exception as e:
            print(f'Error sending notification: {e}')
            return False
    
    def send_multicast_notification(self, device_tokens: list, title: str, body: str, data: dict = None):
        """
        Send push notification to multiple devices.
        
        Args:
            device_tokens: List of FCM device tokens
            title: Notification title
            body: Notification body
            data: Optional data payload (dict)
            
        Returns:
            Number of successful sends
        """
        if not device_tokens:
            return 0
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                tokens=device_tokens,
            )
            
            if data:
                message.data = {str(k): str(v) for k, v in data.items()}
            
            response = messaging.send_multicast(message)
            print(f'Successfully sent {response.success_count} messages')
            return response.success_count
        except Exception as e:
            print(f'Error sending multicast notification: {e}')
            return 0

