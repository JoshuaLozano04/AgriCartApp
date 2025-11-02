from django.urls import path
from . import views

urlpatterns = [
    path('messages/conversation/create/', views.create_or_get_conversation, name='create_or_get_conversation'),
    path('messages/conversations/', views.get_user_conversations, name='get_user_conversations'),
    path('messages/conversation/<str:conversation_id>/', views.get_conversation_messages, name='get_conversation_messages'),
    path('messages/conversation/<str:conversation_id>/mark-read/', views.mark_conversation_read, name='mark_conversation_read'),
    path('messages/send/', views.send_message_rest, name='send_message_rest'),
]

