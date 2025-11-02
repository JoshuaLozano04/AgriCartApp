"""
URL configuration for agricart_api project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.payments import views as payment_views

urlpatterns = [
    path('admin/', admin.site.urls),
    # Payment pages (public, accessible without /api prefix for PayMongo redirects)
    path('payment/redirect/', payment_views.payment_redirect, name='payment_redirect'),
    path('payment/success/', payment_views.payment_success, name='payment_success'),
    path('payment/failed/', payment_views.payment_failed, name='payment_failed'),
    # API endpoints
    path('api/', include('apps.users.urls')),
    path('api/', include('apps.products.urls')),
    path('api/', include('apps.orders.urls')),
    path('api/', include('apps.payments.urls')),
    path('api/', include('apps.chat.urls')),
    path('api/', include('apps.analytics.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
