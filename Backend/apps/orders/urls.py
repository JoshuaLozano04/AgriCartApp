from django.urls import path
from . import views

urlpatterns = [
    path('orders/', views.list_orders, name='list_orders'),
    path('orders/create/', views.create_order, name='create_order'),
    path('orders/<str:order_id>/', views.get_order, name='get_order'),
    path('orders/<str:order_id>/update-status/', views.update_order_status, name='update_order_status'),
]

