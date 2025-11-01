from django.urls import path
from . import views

urlpatterns = [
    path('analytics/sales/', views.get_sales_analytics, name='get_sales_analytics'),
]

