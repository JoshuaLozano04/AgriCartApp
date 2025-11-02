from django.urls import path
from . import views

urlpatterns = [
    path('payments/create/', views.create_payment, name='create_payment'),
    path('payments/confirm/', views.confirm_payment, name='confirm_payment'),
    # Place more specific pattern before generic ones to ensure proper matching
    path('payments/order/<str:order_id>/', views.get_payment, name='get_payment'),
    # Note: payment/success/ and payment/failed/ are defined in main urls.py 
    # (without /api prefix) for PayMongo redirect compatibility
]

