"""
User authentication and profile views.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from firebase_admin import firestore
from utils.firebase_service import FirebaseService
from utils.mongodb import MongoDBService
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserVerificationSerializer,
    UserProfileSerializer
)
import hashlib
import uuid


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """User registration endpoint."""
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        
        # Generate user ID
        user_id = str(uuid.uuid4())
        
        # Hash password (in production, use proper password hashing)
        password_hash = hashlib.sha256(data['password'].encode()).hexdigest()
        
        # Create user document in Firestore
        user_data = {
            'user_id': user_id,
            'email': data['email'],
            'password_hash': password_hash,
            'full_name': data['full_name'],
            'phone_number': data['phone_number'],
            'role': data['role'],
            'address': data.get('address', ''),
            'is_verified': False,
            'verification_status': {
                'id_verified': False,
                'phone_verified': False
            },
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        try:
            FirebaseService.create_document('users', user_data, user_id)
            return Response({
                'success': True,
                'message': 'User registered successfully',
                'user_id': user_id
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Registration failed: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """User login endpoint."""
    serializer = UserLoginSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        email = data['email']
        password = data['password']
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        # Query Firestore for user
        try:
            users_ref = FirebaseService.get_collection('users')
            query = users_ref.where('email', '==', email).limit(1)
            docs = list(query.stream())
            
            if docs:
                user_doc = docs[0]
                user_data = user_doc.to_dict()
                
                if user_data.get('password_hash') == password_hash:
                    return Response({
                        'success': True,
                        'message': 'Login successful',
                        'user': {
                            'user_id': user_data.get('user_id'),
                            'email': user_data.get('email'),
                            'full_name': user_data.get('full_name'),
                            'role': user_data.get('role'),
                            'is_verified': user_data.get('is_verified', False)
                        }
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': 'Invalid credentials'
                    }, status=status.HTTP_401_UNAUTHORIZED)
            else:
                return Response({
                    'success': False,
                    'message': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Login failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def verify_user(request):
    """User verification endpoint (ID or phone)."""
    serializer = UserVerificationSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        user_id = data['user_id']
        verification_type = data['verification_type']
        verification_data = data['verification_data']
        
        try:
            user_doc = FirebaseService.get_document('users', user_id)
            if not user_doc:
                return Response({
                    'success': False,
                    'message': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            user_data = user_doc.to_dict()
            verification_status = user_data.get('verification_status', {})
            
            if verification_type == 'id':
                # Store ID image in MongoDB GridFS
                mongodb = MongoDBService()
                image_id = mongodb.upload_image(
                    verification_data.encode() if isinstance(verification_data, str) else verification_data,
                    filename=f'{user_id}_id.jpg',
                    content_type='image/jpeg'
                )
                
                # Update verification status
                verification_status['id_verified'] = True
                verification_status['id_image_id'] = image_id
                mongodb.close()
            elif verification_type == 'phone':
                # In production, verify phone with OTP
                verification_status['phone_verified'] = True
            
            # Check if all verifications are complete
            is_verified = verification_status.get('id_verified', False) and \
                         verification_status.get('phone_verified', False)
            
            # Update user document
            FirebaseService.update_document('users', user_id, {
                'verification_status': verification_status,
                'is_verified': is_verified,
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            return Response({
                'success': True,
                'message': f'{verification_type.upper()} verification submitted',
                'is_verified': is_verified
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Verification failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_profile(request, user_id):
    """Get user profile endpoint."""
    try:
        user_doc = FirebaseService.get_document('users', user_id)
        if not user_doc:
            return Response({
                'success': False,
                'message': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        user_data = user_doc.to_dict()
        user_data.pop('password_hash', None)  # Remove sensitive data
        
        return Response({
            'success': True,
            'user': user_data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve profile: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
def update_profile(request, user_id):
    """Update user profile endpoint."""
    serializer = UserProfileSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        # Remove user_id from update data
        data.pop('user_id', None)
        data['updated_at'] = firestore.SERVER_TIMESTAMP
        
        try:
            success = FirebaseService.update_document('users', user_id, data)
            if success:
                return Response({
                    'success': True,
                    'message': 'Profile updated successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to update profile'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Update failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
