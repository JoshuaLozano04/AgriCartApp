"""
Firebase Admin SDK service for Firestore operations.
"""
import firebase_admin
from firebase_admin import credentials, firestore
from django.conf import settings
import os


class FirebaseService:
    """Service class for Firebase Firestore operations."""
    
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """Initialize Firebase Admin SDK."""
        if not cls._initialized:
            service_account_path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
            if service_account_path and os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
            else:
                # Use default credentials if no service account file provided
                firebase_admin.initialize_app()
            cls._initialized = True
            cls.db = firestore.client()
    
    @classmethod
    def get_db(cls):
        """Get Firestore database instance."""
        if not cls._initialized:
            cls.initialize()
        return cls.db
    
    @classmethod
    def get_collection(cls, collection_name: str):
        """
        Get a Firestore collection reference.
        
        Args:
            collection_name: Name of the collection
            
        Returns:
            Collection reference
        """
        db = cls.get_db()
        return db.collection(collection_name)
    
    @classmethod
    def create_document(cls, collection_name: str, data: dict, doc_id: str = None):
        """
        Create a document in Firestore.
        
        Args:
            collection_name: Name of the collection
            data: Document data dictionary
            doc_id: Optional document ID (auto-generated if not provided)
            
        Returns:
            Document reference
        """
        collection = cls.get_collection(collection_name)
        if doc_id:
            doc_ref = collection.document(doc_id)
            doc_ref.set(data)
            return doc_ref
        else:
            doc_ref = collection.add(data)
            return doc_ref[1]
    
    @classmethod
    def get_document(cls, collection_name: str, doc_id: str):
        """
        Get a document from Firestore.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            
        Returns:
            Document snapshot or None if not found
        """
        doc_ref = cls.get_collection(collection_name).document(doc_id)
        doc = doc_ref.get()
        if doc.exists:
            return doc
        return None
    
    @classmethod
    def update_document(cls, collection_name: str, doc_id: str, data: dict):
        """
        Update a document in Firestore.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            data: Updated data dictionary
            
        Returns:
            True if successful, False otherwise
        """
        try:
            doc_ref = cls.get_collection(collection_name).document(doc_id)
            doc_ref.update(data)
            return True
        except Exception:
            return False
    
    @classmethod
    def delete_document(cls, collection_name: str, doc_id: str):
        """
        Delete a document from Firestore.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            
        Returns:
            True if successful, False otherwise
        """
        try:
            doc_ref = cls.get_collection(collection_name).document(doc_id)
            doc_ref.delete()
            return True
        except Exception:
            return False
    
    @classmethod
    def query_collection(cls, collection_name: str, filters: list = None, order_by: str = None, limit: int = None):
        """
        Query a Firestore collection.
        
        Args:
            collection_name: Name of the collection
            filters: List of tuples (field, operator, value) for filtering
            order_by: Field name to order by
            limit: Maximum number of documents to return
            
        Returns:
            List of document snapshots
        """
        query = cls.get_collection(collection_name)
        
        if filters:
            for field, operator, value in filters:
                query = query.where(field, operator, value)
        
        if order_by:
            query = query.order_by(order_by)
        
        if limit:
            query = query.limit(limit)
        
        return query.stream()

