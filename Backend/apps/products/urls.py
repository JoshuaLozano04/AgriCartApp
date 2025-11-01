from django.urls import path
from . import views

urlpatterns = [
    path('products/', views.list_products, name='list_products'),
    path('products/create/', views.create_product, name='create_product'),
    path('products/<str:product_id>/', views.get_product, name='get_product'),
    path('products/<str:product_id>/update/', views.update_product, name='update_product'),
    path('products/<str:product_id>/delete/', views.delete_product, name='delete_product'),
    path('images/<str:image_id>/', views.get_image, name='get_image'),
]

