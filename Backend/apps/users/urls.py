from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('auth/verify/', views.verify_user, name='verify_user'),
    path('users/profile/', views.get_profile, name='get_profile'),
    path('users/profile/update/', views.update_profile, name='update_profile'),
    path('notifications/register-token/', views.register_fcm_token, name='register_fcm_token'),
    path('notifications/', views.list_notifications, name='list_notifications'),
    path('notifications/<str:notification_id>/read/', views.mark_notification_read, name='mark_notification_read'),
    path('notifications/read-all/', views.mark_all_notifications_read, name='mark_all_notifications_read'),
    path('notifications/test-create/', views.test_create_notification, name='test_create_notification'),
]

