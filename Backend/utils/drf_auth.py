"""
Django REST Framework authentication class for JWT tokens.
"""
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from utils.jwt_auth import verify_token
from utils.middleware import SimpleUser


class JWTAuthentication(BaseAuthentication):
    """
    JWT token authentication for Django REST Framework.
    Extracts token from Authorization header and sets request.user.
    """
    
    def authenticate(self, request):
        """
        Authenticate the request using JWT token.
        
        Returns:
            (user, token) tuple if authentication succeeds, None otherwise
        """
        import sys
        
        # Extract token from Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '') or request.META.get('Authorization', '')
        
        if not auth_header:
            # Don't log for public endpoints (noise reduction)
            # The view's permission_classes will handle authorization
            return None
        
        if not auth_header.startswith('Bearer '):
            print('DEBUG DRF Auth: Not Bearer token', file=sys.stderr)
            return None
        
        try:
            token = auth_header.split('Bearer ')[1].strip()
        except (IndexError, AttributeError):
            print('DEBUG DRF Auth: Token extraction failed', file=sys.stderr)
            return None
        
        # Verify token
        user_data = verify_token(token)
        if not user_data:
            print('DEBUG DRF Auth: Token verification failed', file=sys.stderr)
            return None
        
        # Create SimpleUser object
        user = SimpleUser(
            user_id=user_data['user_id'],
            email=user_data['email'],
            role=user_data['role']
        )
        
        print(f'DEBUG DRF Auth: Authenticated user_id={user.user_id}', file=sys.stderr)
        
        return (user, token)

