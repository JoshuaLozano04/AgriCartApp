from django.urls import path
from . import views

urlpatterns = [
    path('payments/create/', views.create_payment, name='create_payment'),
    path('payments/confirm/', views.confirm_payment, name='confirm_payment'),
]

