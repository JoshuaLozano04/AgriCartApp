from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('auth/verify/', views.verify_user, name='verify_user'),
    path('users/<str:user_id>/', views.get_profile, name='get_profile'),
    path('users/<str:user_id>/update/', views.update_profile, name='update_profile'),
]

