"""
Unified MongoDB service for all data operations (collections + GridFS).
Comprehensive CRUD operations with validation helpers.
"""
import pymongo
from gridfs import GridFS
from bson import ObjectId
from datetime import datetime, timezone
from django.conf import settings
from typing import BinaryIO, Optional, Dict, List, Any, Tuple
from pymongo.errors import PyMongoError, DuplicateKeyError
import re


class MongoDBService:
    """Unified service class for MongoDB operations (collections + GridFS)."""
    
    _client = None
    _db = None
    _fs = None
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """Initialize MongoDB connection."""
        if not cls._initialized:
            try:
                cls._client = pymongo.MongoClient(settings.MONGODB_CONNECTION_STRING)
                cls._db = cls._client[settings.MONGODB_DATABASE_NAME]
                cls._fs = GridFS(cls._db)
                cls._initialized = True
            except Exception as e:
                print(f'Error initializing MongoDB: {e}')
                raise
    
    @classmethod
    def get_db(cls):
        """Get MongoDB database instance."""
        if not cls._initialized:
            cls.initialize()
        return cls._db
    
    @classmethod
    def get_collection(cls, collection_name: str):
        """
        Get a MongoDB collection reference.
        
        Args:
            collection_name: Name of the collection
            
        Returns:
            Collection reference
        """
        db = cls.get_db()
        return db[collection_name]
    
    @classmethod
    def create_document(cls, collection_name: str, data: dict, doc_id: str = None):
        """
        Create a document in MongoDB collection.
        
        Args:
            collection_name: Name of the collection
            data: Document data dictionary
            doc_id: Optional document ID (ObjectId if not provided)
            
        Returns:
            Document ID as string
        """
        collection = cls.get_collection(collection_name)
        
        # Convert SERVER_TIMESTAMP strings to actual datetime
        if 'created_at' in data and data['created_at'] == 'SERVER_TIMESTAMP':
            data['created_at'] = datetime.now(timezone.utc)
        if 'updated_at' in data and data['updated_at'] == 'SERVER_TIMESTAMP':
            data['updated_at'] = datetime.now(timezone.utc)
        
        try:
            if doc_id:
                # Use provided ID
                data['_id'] = doc_id
                collection.insert_one(data)
                return doc_id
            else:
                # Auto-generate ObjectId
                result = collection.insert_one(data)
                return str(result.inserted_id)
        except PyMongoError as e:
            print(f'Error creating document in {collection_name}: {e}')
            raise
    
    @classmethod
    def get_document(cls, collection_name: str, doc_id: str):
        """
        Get a document from MongoDB collection.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            
        Returns:
            Document dictionary or None if not found
        """
        collection = cls.get_collection(collection_name)
        
        try:
            # Try ObjectId first, then string
            try:
                doc = collection.find_one({'_id': ObjectId(doc_id)})
            except:
                doc = collection.find_one({'_id': doc_id})
            
            if doc:
                # Convert ObjectId to string for JSON serialization
                if '_id' in doc and isinstance(doc['_id'], ObjectId):
                    doc['_id'] = str(doc['_id'])
                # Convert datetime to ISO string
                for key, value in doc.items():
                    if isinstance(value, datetime):
                        doc[key] = value.isoformat()
                return doc
            return None
        except PyMongoError as e:
            print(f'Error getting document from {collection_name}: {e}')
            return None
    
    @classmethod
    def update_document(cls, collection_name: str, doc_id: str, data: dict):
        """
        Update a document in MongoDB collection.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            data: Updated data dictionary
            
        Returns:
            True if successful, False otherwise
        """
        collection = cls.get_collection(collection_name)
        
        # Handle timestamps
        if 'updated_at' in data:
            if isinstance(data['updated_at'], str) and data['updated_at'] == 'SERVER_TIMESTAMP':
                data['updated_at'] = datetime.now(timezone.utc)
        
        try:
            # Try ObjectId first, then string
            try:
                filter_query = {'_id': ObjectId(doc_id)}
            except:
                filter_query = {'_id': doc_id}
            
            result = collection.update_one(filter_query, {'$set': data})
            return result.modified_count > 0
        except PyMongoError as e:
            print(f'Error updating document in {collection_name}: {e}')
            return False
    
    @classmethod
    def delete_document(cls, collection_name: str, doc_id: str):
        """
        Delete a document from MongoDB collection.
        
        Args:
            collection_name: Name of the collection
            doc_id: Document ID
            
        Returns:
            True if successful, False otherwise
        """
        collection = cls.get_collection(collection_name)
        
        try:
            # Try ObjectId first, then string
            try:
                result = collection.delete_one({'_id': ObjectId(doc_id)})
            except:
                result = collection.delete_one({'_id': doc_id})
            
            return result.deleted_count > 0
        except PyMongoError as e:
            print(f'Error deleting document from {collection_name}: {e}')
            return False
    
    @classmethod
    def query_collection(cls, collection_name: str, filters: list = None, order_by: str = None, limit: int = None):
        """
        Query a MongoDB collection.
        
        Args:
            collection_name: Name of the collection
            filters: List of tuples (field, operator, value) for filtering
            order_by: Field name to order by (use '-' prefix for descending)
            limit: Maximum number of documents to return
            
        Returns:
            List of document dictionaries
        """
        collection = cls.get_collection(collection_name)
        
        # Build query from filters
        query = {}
        if filters:
            for field, operator, value in filters:
                if operator == '==':
                    query[field] = value
                elif operator == '>':
                    query[field] = {'$gt': value}
                elif operator == '>=':
                    query[field] = {'$gte': value}
                elif operator == '<':
                    query[field] = {'$lt': value}
                elif operator == '<=':
                    query[field] = {'$lte': value}
                elif operator == '!=':
                    query[field] = {'$ne': value}
                elif operator == 'in':
                    query[field] = {'$in': value}
        
        try:
            cursor = collection.find(query)
            
            # Apply sorting
            if order_by:
                sort_direction = -1 if order_by.startswith('-') else 1
                sort_field = order_by.lstrip('-')
                cursor = cursor.sort(sort_field, sort_direction)
            
            # Apply limit
            if limit:
                cursor = cursor.limit(limit)
            
            # Convert results
            results = []
            for doc in cursor:
                # Convert ObjectId to string
                if '_id' in doc and isinstance(doc['_id'], ObjectId):
                    doc['_id'] = str(doc['_id'])
                # Convert datetime to ISO string
                for key, value in doc.items():
                    if isinstance(value, datetime):
                        doc[key] = value.isoformat()
                results.append(doc)
            
            return results
        except PyMongoError as e:
            print(f'Error querying collection {collection_name}: {e}')
            return []
    
    # GridFS methods (for images)
    @classmethod
    def upload_image(cls, file_data: bytes, filename: str, content_type: str = 'image/jpeg') -> str:
        """
        Upload an image to MongoDB GridFS.
        
        Args:
            file_data: Image binary data
            filename: Original filename
            content_type: MIME type of the image
            
        Returns:
            GridFS file ID as string
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            file_id = cls._fs.put(
                file_data,
                filename=filename,
                content_type=content_type
            )
            return str(file_id)
        except PyMongoError as e:
            print(f'Error uploading image: {e}')
            raise
    
    @classmethod
    def get_image(cls, file_id: str) -> Optional[bytes]:
        """
        Retrieve an image from MongoDB GridFS.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            Image binary data or None if not found
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            file_object = cls._fs.get(ObjectId(file_id))
            return file_object.read()
        except Exception:
            return None
    
    @classmethod
    def get_image_metadata(cls, file_id: str) -> Optional[dict]:
        """
        Get image metadata without retrieving the file.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            Dictionary with metadata or None if not found
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            file_object = cls._fs.get(ObjectId(file_id))
            return {
                'filename': file_object.filename,
                'content_type': file_object.content_type,
                'length': file_object.length,
                'upload_date': file_object.upload_date.isoformat() if file_object.upload_date else None
            }
        except Exception:
            return None
    
    @classmethod
    def delete_image(cls, file_id: str) -> bool:
        """
        Delete an image from MongoDB GridFS.
        
        Args:
            file_id: GridFS file ID
            
        Returns:
            True if deleted, False otherwise
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            cls._fs.delete(ObjectId(file_id))
            return True
        except Exception:
            return False
    
    @classmethod
    def close(cls):
        """Close MongoDB connection."""
        if cls._client:
            cls._client.close()
            cls._initialized = False

    # Validation helpers
    @classmethod
    def validate_email(cls, email: str) -> bool:
        """Validate email format."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))

    @classmethod
    def validate_phone(cls, phone: str) -> bool:
        """Validate phone number (Philippines format or international)."""
        # Remove spaces, dashes, parentheses
        phone = re.sub(r'[\s\-\(\)]', '', phone)
        # Check if starts with + or 0, then digits
        pattern = r'^(\+?63|0)[0-9]{9,10}$'
        return bool(re.match(pattern, phone))

    @classmethod
    def validate_object_id(cls, doc_id: str) -> bool:
        """Validate if string is a valid ObjectId."""
        try:
            ObjectId(doc_id)
            return True
        except:
            return False

    @classmethod
    def sanitize_string(cls, value: str, max_length: Optional[int] = None) -> str:
        """Sanitize string input (strip whitespace, validate length)."""
        if not isinstance(value, str):
            return str(value)
        value = value.strip()
        if max_length and len(value) > max_length:
            return value[:max_length]
        return value

    # Enhanced query methods
    @classmethod
    def find_one_by_field(cls, collection_name: str, field: str, value: Any) -> Optional[Dict]:
        """Find one document by a specific field."""
        collection = cls.get_collection(collection_name)
        try:
            doc = collection.find_one({field: value})
            if doc:
                if '_id' in doc and isinstance(doc['_id'], ObjectId):
                    doc['_id'] = str(doc['_id'])
                for key, val in doc.items():
                    if isinstance(val, datetime):
                        doc[key] = val.isoformat()
            return doc
        except PyMongoError as e:
            print(f'Error finding document by {field} in {collection_name}: {e}')
            return None

    @classmethod
    def find_many_by_field(cls, collection_name: str, field: str, value: Any, limit: Optional[int] = None) -> List[Dict]:
        """Find multiple documents by a specific field."""
        collection = cls.get_collection(collection_name)
        try:
            cursor = collection.find({field: value})
            if limit:
                cursor = cursor.limit(limit)
            
            results = []
            for doc in cursor:
                if '_id' in doc and isinstance(doc['_id'], ObjectId):
                    doc['_id'] = str(doc['_id'])
                for key, val in doc.items():
                    if isinstance(val, datetime):
                        doc[key] = val.isoformat()
                results.append(doc)
            return results
        except PyMongoError as e:
            print(f'Error finding documents by {field} in {collection_name}: {e}')
            return []

    @classmethod
    def exists(cls, collection_name: str, doc_id: str) -> bool:
        """Check if a document exists."""
        return cls.get_document(collection_name, doc_id) is not None

    @classmethod
    def count_documents(cls, collection_name: str, filters: List[Tuple[str, str, Any]] = None) -> int:
        """Count documents matching filters."""
        collection = cls.get_collection(collection_name)
        
        query = {}
        if filters:
            for field, operator, value in filters:
                if operator == '==':
                    query[field] = value
                elif operator == '>':
                    query[field] = {'$gt': value}
                elif operator == '>=':
                    query[field] = {'$gte': value}
                elif operator == '<':
                    query[field] = {'$lt': value}
                elif operator == '<=':
                    query[field] = {'$lte': value}
                elif operator == '!=':
                    query[field] = {'$ne': value}
                elif operator == 'in':
                    query[field] = {'$in': value}
        
        try:
            return collection.count_documents(query)
        except PyMongoError as e:
            print(f'Error counting documents in {collection_name}: {e}')
            return 0

    @classmethod
    def update_many(cls, collection_name: str, filter_query: Dict, update_data: Dict) -> int:
        """Update multiple documents."""
        collection = cls.get_collection(collection_name)
        
        # Handle timestamps
        if 'updated_at' in update_data:
            if isinstance(update_data['updated_at'], str) and update_data['updated_at'] == 'SERVER_TIMESTAMP':
                update_data['updated_at'] = datetime.now(timezone.utc)
        
        try:
            result = collection.update_many(filter_query, {'$set': update_data})
            return result.modified_count
        except PyMongoError as e:
            print(f'Error updating documents in {collection_name}: {e}')
            return 0

    @classmethod
    def delete_many(cls, collection_name: str, filter_query: Dict) -> int:
        """Delete multiple documents."""
        collection = cls.get_collection(collection_name)
        try:
            result = collection.delete_many(filter_query)
            return result.deleted_count
        except PyMongoError as e:
            print(f'Error deleting documents from {collection_name}: {e}')
            return 0

    @classmethod
    def create_index(cls, collection_name: str, field: str, unique: bool = False):
        """Create an index on a field."""
        collection = cls.get_collection(collection_name)
        try:
            collection.create_index(field, unique=unique)
        except PyMongoError as e:
            print(f'Error creating index on {field} in {collection_name}: {e}')

    @classmethod
    def aggregate(cls, collection_name: str, pipeline: List[Dict]) -> List[Dict]:
        """Perform aggregation query."""
        collection = cls.get_collection(collection_name)
        try:
            results = []
            for doc in collection.aggregate(pipeline):
                if '_id' in doc and isinstance(doc['_id'], ObjectId):
                    doc['_id'] = str(doc['_id'])
                for key, val in doc.items():
                    if isinstance(val, datetime):
                        doc[key] = val.isoformat()
                results.append(doc)
            return results
        except PyMongoError as e:
            print(f'Error aggregating in {collection_name}: {e}')
            return []

