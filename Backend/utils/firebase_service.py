"""
Firebase Admin SDK service for FCM (Firebase Cloud Messaging) initialization only.
All data operations now use MongoDB.
"""
import firebase_admin
from firebase_admin import credentials
from django.conf import settings
import os


class FirebaseService:
    """Service class for Firebase Admin SDK initialization (FCM only)."""
    
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """Initialize Firebase Admin SDK for FCM push notifications."""
        if not cls._initialized:
            service_account_path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
            if service_account_path and os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                try:
                    firebase_admin.initialize_app(cred)
                except ValueError:
                    # App already initialized, ignore
                    pass
            else:
                # Use default credentials if no service account file provided
                try:
                    firebase_admin.initialize_app()
                except ValueError:
                    # App already initialized, ignore
                    pass
            cls._initialized = True

