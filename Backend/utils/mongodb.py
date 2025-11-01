"""
MongoDB GridFS utility for image storage and retrieval.
"""
import pymongo
from gridfs import GridFS
from django.conf import settings
from typing import BinaryIO, Optional


class MongoDBService:
    """Service class for MongoDB GridFS operations."""
    
    def __init__(self):
        self.client = pymongo.MongoClient(settings.MONGODB_CONNECTION_STRING)
        self.db = self.client[settings.MONGODB_DATABASE_NAME]
        self.fs = GridFS(self.db)
    
    def upload_image(self, file_data: bytes, filename: str, content_type: str = 'image/jpeg') -> str:
        """
        Upload an image to MongoDB GridFS.
        
        Args:
            file_data: Image binary data
            filename: Original filename
            content_type: MIME type of the image
            
        Returns:
            GridFS file ID as string
        """
        file_id = self.fs.put(
            file_data,
            filename=filename,
            content_type=content_type
        )
        return str(file_id)
    
    def get_image(self, file_id: str) -> Optional[bytes]:
        """
        Retrieve an image from MongoDB GridFS.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            Image binary data or None if not found
        """
        try:
            file_object = self.fs.get(file_id)
            return file_object.read()
        except Exception:
            return None
    
    def get_image_metadata(self, file_id: str) -> Optional[dict]:
        """
        Get image metadata without retrieving the file.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            Dictionary with metadata or None if not found
        """
        try:
            file_object = self.fs.get(file_id)
            return {
                'filename': file_object.filename,
                'content_type': file_object.content_type,
                'length': file_object.length,
                'upload_date': file_object.upload_date
            }
        except Exception:
            return None
    
    def delete_image(self, file_id: str) -> bool:
        """
        Delete an image from MongoDB GridFS.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            True if deleted, False otherwise
        """
        try:
            self.fs.delete(file_id)
            return True
        except Exception:
            return False
    
    def close(self):
        """Close MongoDB connection."""
        self.client.close()

