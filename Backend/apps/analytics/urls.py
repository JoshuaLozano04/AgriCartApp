from django.urls import path
from . import views

urlpatterns = [
    path('analytics/sales/', views.get_sales_analytics, name='get_sales_analytics'),
    path('analytics/dashboard/', views.get_dashboard_summary, name='get_dashboard_summary'),
]

