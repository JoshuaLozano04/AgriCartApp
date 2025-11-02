"""
Middleware to exempt API routes from CSRF protection.
"""
from django.utils.deprecation import MiddlewareMixin
from django.middleware.csrf import CsrfViewMiddleware


class DisableCSRFForAPI(MiddlewareMixin):
    """
    Middleware to disable CSRF protection for API routes.
    Since we use JWT tokens for authentication, CSRF protection is not needed.
    """
    
    def process_view(self, request, callback, callback_args, callback_kwargs):
        # Exempt all /api/ routes from CSRF
        if request.path.startswith('/api/'):
            setattr(request, '_dont_enforce_csrf_checks', True)
        # Exempt payment result pages (public pages accessed from PayMongo redirects)
        if request.path.startswith('/payment/'):
            setattr(request, '_dont_enforce_csrf_checks', True)
        return None

