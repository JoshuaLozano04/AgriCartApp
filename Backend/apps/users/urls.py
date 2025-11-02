from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('auth/verify/', views.verify_user, name='verify_user'),
    path('users/profile/', views.get_profile, name='get_profile'),
    path('users/profile/update/', views.update_profile, name='update_profile'),
]

