"""
ASGI middleware for authenticating WebSocket connections using JWT tokens.
Extracts JWT from query parameters or headers and populates scope['user'].
"""
from urllib.parse import parse_qs
from channels.db import database_sync_to_async
from utils.jwt_auth import verify_token


class SimpleUser:
    """Simple user object to attach to scope."""
    
    def __init__(self, user_id, email, role):
        self.user_id = user_id
        self.email = email
        self.role = role
        self.is_authenticated = True


class TokenAuthMiddleware:
    """
    Middleware to authenticate WebSocket connections using JWT.
    Extracts token from:
    1. Query parameter: ?token=<jwt>
    2. Sec-WebSocket-Protocol header (future support)
    3. Authorization header (if available in scope)
    """
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        # Only process WebSocket connections
        if scope['type'] != 'websocket':
            return await self.app(scope, receive, send)
        
        # Extract token from query string
        query_string = scope.get('query_string', b'').decode()
        token = None
        
        print(f'TokenAuthMiddleware: Query string: {query_string}')
        
        if 'token=' in query_string:
            # Parse query string to extract token
            query_params = parse_qs(query_string)
            token_list = query_params.get('token', [])
            if token_list:
                token = token_list[0]
                print(f'TokenAuthMiddleware: Extracted token from query: {token[:20]}...')
        
        # If no token in query, check headers (future enhancement)
        if not token:
            headers = dict(scope.get('headers', []))
            # Check Authorization header
            auth_header = headers.get(b'authorization', b'').decode()
            if auth_header.startswith('Bearer '):
                token = auth_header[7:]
                print(f'TokenAuthMiddleware: Extracted token from header: {token[:20]}...')
        
        # Verify token and populate user
        if token:
            user_data = verify_token(token)
            if user_data:
                print(f'TokenAuthMiddleware: Token verified for user_id: {user_data.get("user_id")}')
                scope['user'] = SimpleUser(
                    user_id=user_data.get('user_id'),
                    email=user_data.get('email'),
                    role=user_data.get('role')
                )
            else:
                print('TokenAuthMiddleware: Token verification failed')
                scope['user'] = None
        else:
            print('TokenAuthMiddleware: No token found in request')
            scope['user'] = None
        
        return await self.app(scope, receive, send)


def TokenAuthMiddlewareStack(app):
    """
    Convenience function to wrap app with TokenAuthMiddleware.
    Usage: TokenAuthMiddlewareStack(URLRouter(...))
    """
    return TokenAuthMiddleware(app)
