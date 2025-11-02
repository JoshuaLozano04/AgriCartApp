"""
Custom authentication middleware for JWT tokens.
"""
from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from utils.jwt_auth import verify_token
import json


class SimpleUser:
    """Simple user object to attach to request."""
    def __init__(self, user_id: str, email: str, role: str):
        self.user_id = user_id
        self.email = email
        self.role = role
        self.is_authenticated = True
        self.is_active = True  # Required by DRF
        self.is_anonymous = False  # Required by DRF/Django
        self.pk = user_id  # Primary key for compatibility
        self.id = user_id  # Alternative ID attribute
        self.username = email  # Some DRF components expect username
    
    def __str__(self):
        return f"SimpleUser(user_id={self.user_id}, email={self.email}, role={self.role})"
    
    def __repr__(self):
        return self.__str__()


class JWTAuthenticationMiddleware(MiddlewareMixin):
    """
    Middleware to authenticate requests using JWT tokens.
    Extracts token from Authorization header and sets request.user.
    """
    
    # URLs that don't require authentication
    PUBLIC_URLS = [
        '/api/auth/register/',
        '/api/auth/login/',
        '/api/products/',
        '/api/images/',
        '/payment/redirect/',
        '/payment/success/',
        '/payment/failed/',
        '/admin/',  # Admin pages handled by Django
    ]
    
    def _authenticate_request(self, request):
        """Authenticate request using JWT token."""
        import sys
        # Skip authentication for public URLs
        if any(request.path.startswith(url) for url in self.PUBLIC_URLS):
            return None
        
        # Skip for OPTIONS requests (CORS preflight)
        if request.method == 'OPTIONS':
            return None
        
        # Extract token from Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '') or request.META.get('Authorization', '')
        
        if not auth_header:
            print('DEBUG _authenticate: No auth header', file=sys.stderr)
            return None
        
        if not auth_header.startswith('Bearer '):
            print(f'DEBUG _authenticate: Not Bearer: {auth_header[:30]}', file=sys.stderr)
            return None
        
        try:
            token = auth_header.split('Bearer ')[1].strip()
        except (IndexError, AttributeError):
            print('DEBUG _authenticate: Token extraction failed', file=sys.stderr)
            return None
        
        # Verify token
        user_data = verify_token(token)
        if not user_data:
            print('DEBUG _authenticate: Token verification failed', file=sys.stderr)
            return None
        
        # Set user on request (this overrides Django's AnonymousUser)
        request.user = SimpleUser(
            user_id=user_data['user_id'],
            email=user_data['email'],
            role=user_data['role']
        )
        
        print(f'DEBUG _authenticate: Set request.user to SimpleUser with user_id={request.user.user_id}', file=sys.stderr)
        
        return None
    
    def process_request(self, request):
        """Process request and authenticate using JWT token."""
        return self._authenticate_request(request)
    
    def process_view(self, request, view_func, view_args, view_kwargs):
        """Process view - set user just before view executes."""
        import sys
        # Re-authenticate in case something reset request.user
        print(f'DEBUG process_view: Before auth - request.user type={type(request.user)}', file=sys.stderr)
        result = self._authenticate_request(request)
        if result is not None:
            return result
        print(f'DEBUG process_view: After auth - request.user type={type(request.user)}, has user_id={hasattr(request.user, "user_id") if hasattr(request, "user") else False}', file=sys.stderr)
        return None
    
    def process_response(self, request, response):
        """Handle 401 responses for unauthenticated requests."""
        if hasattr(request, 'user') and request.user is None:
            # Check if this is an authenticated endpoint
            if not any(request.path.startswith(url) for url in self.PUBLIC_URLS):
                if request.method != 'OPTIONS':
                    # Only return 401 if it's not already an error response
                    if response.status_code == 200:
                        return JsonResponse(
                            {'success': False, 'message': 'Authentication required'},
                            status=401
                        )
        return response

