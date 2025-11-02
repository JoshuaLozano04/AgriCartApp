"""
User authentication and profile views.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from utils.mongodb_service import MongoDBService
from utils.jwt_auth import generate_token
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
        
        # Validate email format
        email = MongoDBService.sanitize_string(data['email'].lower())
        if not MongoDBService.validate_email(email):
            return Response({
                'success': False,
                'message': 'Invalid email format'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate phone number
        phone_number = MongoDBService.sanitize_string(data['phone_number'])
        if not MongoDBService.validate_phone(phone_number):
            return Response({
                'success': False,
                'message': 'Invalid phone number format. Use Philippine format (e.g., +639123456789 or 09123456789)'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if email already exists
        existing_user = MongoDBService.find_one_by_field('users', 'email', email)
        if existing_user:
            return Response({
                'success': False,
                'message': 'Email already registered'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate user ID
        user_id = str(uuid.uuid4())
        
        # Hash password (in production, use bcrypt or similar)
        password_hash = hashlib.sha256(data['password'].encode()).hexdigest()
        
        # Sanitize name and address
        full_name = MongoDBService.sanitize_string(data['full_name'], max_length=255)
        address = MongoDBService.sanitize_string(data.get('address', ''), max_length=500)
        
        # Create user document in MongoDB
        user_data = {
            'user_id': user_id,
            'email': email,
            'password_hash': password_hash,
            'full_name': full_name,
            'phone_number': phone_number,
            'role': data['role'],
            'address': address,
            'is_verified': False,
            'verification_status': {
                'id_verified': False,
                'phone_verified': False
            },
            'created_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        }
        
        try:
            MongoDBService.create_document('users', user_data, user_id)
            
            # Create unique index on email (if not exists)
            try:
                MongoDBService.create_index('users', 'email', unique=True)
            except:
                pass  # Index may already exist
            
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
        
        # Query MongoDB for user
        try:
            email_lower = email.lower().strip()
            user_data = MongoDBService.find_one_by_field('users', 'email', email_lower)
            
            if user_data:
                
                if user_data.get('password_hash') == password_hash:
                    # Generate JWT token
                    token_data = {
                        'user_id': user_data.get('user_id'),
                        'email': user_data.get('email'),
                        'role': user_data.get('role'),
                    }
                    token = generate_token(token_data)
                    
                    return Response({
                        'success': True,
                        'message': 'Login successful',
                        'token': token,
                        'user': {
                            'user_id': user_data.get('user_id'),
                            'email': user_data.get('email'),
                            'full_name': user_data.get('full_name'),
                            'phone_number': user_data.get('phone_number'),
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
    """Verify current user account (ID or phone)."""
    # Check authentication - ensure it's our SimpleUser, not AnonymousUser
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    serializer = UserVerificationSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        verification_type = data['verification_type']
        verification_data = data['verification_data']
        
        try:
            user_data = MongoDBService.get_document('users', user_id)
            if not user_data:
                return Response({
                    'success': False,
                    'message': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            verification_status = user_data.get('verification_status', {})
            
            if verification_type == 'id':
                # Store ID image in MongoDB GridFS
                image_id = MongoDBService.upload_image(
                    verification_data.encode() if isinstance(verification_data, str) else verification_data,
                    filename=f'{user_id}_id.jpg',
                    content_type='image/jpeg'
                )
                
                # Update verification status
                verification_status['id_verified'] = True
                verification_status['id_image_id'] = image_id
            elif verification_type == 'phone':
                # In production, verify phone with OTP
                verification_status['phone_verified'] = True
            
            # Check if all verifications are complete
            is_verified = verification_status.get('id_verified', False) and \
                         verification_status.get('phone_verified', False)
            
            # Update user document
            MongoDBService.update_document('users', user_id, {
                'verification_status': verification_status,
                'is_verified': is_verified,
                'updated_at': 'SERVER_TIMESTAMP'
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
def get_profile(request):
    """Get current user profile endpoint."""
    import sys
    # Debug: Check what we have
    print(f'DEBUG get_profile: request.user type={type(request.user)}', file=sys.stderr)
    print(f'DEBUG get_profile: hasattr user={hasattr(request, "user")}', file=sys.stderr)
    if hasattr(request, 'user'):
        print(f'DEBUG get_profile: request.user={request.user}', file=sys.stderr)
        print(f'DEBUG get_profile: hasattr user_id={hasattr(request.user, "user_id")}', file=sys.stderr)
        if hasattr(request.user, 'user_id'):
            print(f'DEBUG get_profile: user_id={request.user.user_id}', file=sys.stderr)
    
    # Check authentication - ensure it's our SimpleUser, not AnonymousUser
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        print('DEBUG get_profile: Authentication check failed', file=sys.stderr)
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    try:
        user_data = MongoDBService.get_document('users', user_id)
        if not user_data:
            return Response({
                'success': False,
                'message': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
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
def update_profile(request):
    """Update current user profile endpoint."""
    # Check authentication - ensure it's our SimpleUser, not AnonymousUser
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    serializer = UserProfileSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        # Remove user_id from update data
        data.pop('user_id', None)
        data['updated_at'] = 'SERVER_TIMESTAMP'
        
        try:
            success = MongoDBService.update_document('users', user_id, data)
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
