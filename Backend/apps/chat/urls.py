from django.urls import path
from . import views

urlpatterns = [
    path('messages/send/', views.send_message, name='send_message'),
    path('messages/conversation/', views.get_conversation, name='get_conversation'),
]

