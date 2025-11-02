"""
JWT token generation and verification utilities.
"""
import jwt
from datetime import datetime, timedelta
from django.conf import settings
from typing import Dict, Optional


def generate_token(user_data: Dict) -> str:
    """
    Generate JWT token for a user.
    
    Args:
        user_data: Dictionary containing user_id, email, role
        
    Returns:
        JWT token string
    """
    expiration_days = getattr(settings, 'JWT_EXPIRATION_DAYS', 7)
    expiration = datetime.utcnow() + timedelta(days=expiration_days)
    
    payload = {
        'user_id': user_data.get('user_id'),
        'email': user_data.get('email'),
        'role': user_data.get('role'),
        'exp': expiration,
        'iat': datetime.utcnow(),
    }
    
    secret_key = getattr(settings, 'JWT_SECRET_KEY', settings.SECRET_KEY)
    algorithm = getattr(settings, 'JWT_ALGORITHM', 'HS256')
    
    token = jwt.encode(payload, secret_key, algorithm=algorithm)
    return token


def verify_token(token: str) -> Optional[Dict]:
    """
    Verify and decode JWT token.
    
    Args:
        token: JWT token string
        
    Returns:
        Dictionary with user data if valid, None if invalid
    """
    try:
        secret_key = getattr(settings, 'JWT_SECRET_KEY', settings.SECRET_KEY)
        algorithm = getattr(settings, 'JWT_ALGORITHM', 'HS256')
        
        payload = jwt.decode(token, secret_key, algorithms=[algorithm])
        return {
            'user_id': payload.get('user_id'),
            'email': payload.get('email'),
            'role': payload.get('role'),
        }
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

