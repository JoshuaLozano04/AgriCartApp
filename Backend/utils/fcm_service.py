"""
Firebase Cloud Messaging service for push notifications.
"""
import requests
from django.conf import settings


class FCMService:
    """Service for sending push notifications via FCM."""
    
    FCM_URL = "https://fcm.googleapis.com/fcm/send"
    
    def __init__(self):
        self.server_key = settings.FCM_SERVER_KEY
    
    def send_notification(self, device_token: str, title: str, body: str, data: dict = None):
        """
        Send push notification to a device.
        
        Args:
            device_token: FCM device token
            title: Notification title
            body: Notification body
            data: Optional data payload
            
        Returns:
            True if successful, False otherwise
        """
        if not self.server_key:
            return False
        
        headers = {
            'Authorization': f'key={self.server_key}',
            'Content-Type': 'application/json'
        }
        
        payload = {
            'to': device_token,
            'notification': {
                'title': title,
                'body': body
            }
        }
        
        if data:
            payload['data'] = data
        
        try:
            response = requests.post(self.FCM_URL, json=payload, headers=headers)
            return response.status_code == 200
        except Exception:
            return False

