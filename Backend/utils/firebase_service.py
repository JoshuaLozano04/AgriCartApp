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
            try:
                if service_account_path and os.path.exists(service_account_path):
                    try:
                        cred = credentials.Certificate(service_account_path)
                        firebase_admin.initialize_app(cred)
                    except Exception as e:
                        # Log the error and continue without crashing the app
                        print(f'Firebase initialization with service account failed: {e}')
                else:
                    try:
                        firebase_admin.initialize_app()
                    except Exception as e:
                        # No default credentials available or already initialized
                        print(f'Firebase default initialization skipped/failed: {e}')
            except Exception as outer_e:
                # Catch any unexpected errors during initialization path checks
                print(f'Unexpected error during FirebaseService.initialize: {outer_e}')
            finally:
                # Mark as initialized to avoid repeated attempts at startup
                cls._initialized = True

