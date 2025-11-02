"""
Analytics views for sales data, trends, and insights.
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from utils.mongodb_service import MongoDBService
from datetime import datetime, timedelta
from collections import defaultdict


@api_view(['GET'])
def get_sales_analytics(request):
    """Get comprehensive sales analytics for a seller."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Only sellers can view analytics
    if request.user.role != 'seller':
        return Response({
            'success': False,
            'message': 'Only sellers can view sales analytics'
        }, status=status.HTTP_403_FORBIDDEN)
    
    seller_id = request.user.user_id
    
    # Get date range from query params
    start_date = request.query_params.get('start_date')
    end_date = request.query_params.get('end_date')
    
    try:
        # Build filters
        filters = [('seller_id', '==', seller_id)]
        
        # Get all orders for this seller
        all_orders = MongoDBService.query_collection('orders', filters=filters)
        
        # Filter by date range if provided
        if start_date or end_date:
            filtered_orders = []
            for order in all_orders:
                order_date_str = order.get('created_at')
                if order_date_str:
                    try:
                        order_date = datetime.fromisoformat(order_date_str.replace('Z', '+00:00'))
                        if start_date:
                            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                            if order_date < start_dt:
                                continue
                        if end_date:
                            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                            if order_date > end_dt:
                                continue
                        filtered_orders.append(order)
                    except:
                        continue
            orders = filtered_orders
        else:
            orders = all_orders
        
        # Calculate metrics - count revenue for paid orders (payment successful) or delivered orders
        total_revenue = sum(
            order.get('total_amount', 0) 
            for order in orders 
            if order.get('payment_status') == 'paid' or order.get('status') == 'delivered'
        )
        total_orders = len(orders)
        pending_orders = len([o for o in orders if o.get('status') == 'pending'])
        confirmed_orders = len([o for o in orders if o.get('status') == 'confirmed'])
        processing_orders = len([o for o in orders if o.get('status') == 'processing'])
        shipped_orders = len([o for o in orders if o.get('status') == 'shipped'])
        delivered_orders = len([o for o in orders if o.get('status') == 'delivered'])
        cancelled_orders = len([o for o in orders if o.get('status') == 'cancelled'])
        
        # Revenue trends (daily for last 30 days) - count paid or delivered orders
        revenue_trends = defaultdict(float)
        for order in orders:
            if order.get('payment_status') == 'paid' or order.get('status') == 'delivered':
                order_date_str = order.get('created_at')
                if order_date_str:
                    try:
                        order_date = datetime.fromisoformat(order_date_str.replace('Z', '+00:00'))
                        date_key = order_date.strftime('%Y-%m-%d')
                        revenue_trends[date_key] += order.get('total_amount', 0)
                    except:
                        pass
        
        # Sort and format revenue trends
        sorted_trends = sorted(revenue_trends.items())
        revenue_trends_list = [{'date': date, 'revenue': revenue} for date, revenue in sorted_trends[-30:]]
        
        # Top products - count paid or delivered orders
        product_sales = defaultdict(lambda: {'quantity_sold': 0, 'revenue': 0.0, 'product_name': ''})
        for order in orders:
            if order.get('payment_status') == 'paid' or order.get('status') == 'delivered':
                for item in order.get('items', []):
                    product_id = item.get('product_id')
                    quantity = item.get('quantity', 0)
                    price = item.get('price', 0)
                    
                    product_sales[product_id]['quantity_sold'] += quantity
                    product_sales[product_id]['revenue'] += quantity * price
                    
                    # Get product name
                    if not product_sales[product_id]['product_name']:
                        product = MongoDBService.get_document('products', product_id)
                        if product:
                            product_sales[product_id]['product_name'] = product.get('name', 'Unknown')
        
        # Sort top products by revenue
        top_products_sorted = sorted(
            product_sales.items(),
            key=lambda x: x[1]['revenue'],
            reverse=True
        )[:10]
        
        top_products = [
            {
                'product_id': pid,
                'product_name': data['product_name'],
                'quantity_sold': data['quantity_sold'],
                'revenue': round(data['revenue'], 2)
            }
            for pid, data in top_products_sorted
        ]
        
        # Category performance - count paid or delivered orders
        category_performance = defaultdict(lambda: {'revenue': 0.0, 'orders': 0, 'quantity': 0})
        for order in orders:
            if order.get('payment_status') == 'paid' or order.get('status') == 'delivered':
                category_performance['all']['revenue'] += order.get('total_amount', 0)
                category_performance['all']['orders'] += 1
                
                for item in order.get('items', []):
                    product_id = item.get('product_id')
                    product = MongoDBService.get_document('products', product_id)
                    if product:
                        category = product.get('category', 'other')
                        quantity = item.get('quantity', 0)
                        price = item.get('price', 0)
                        
                        category_performance[category]['revenue'] += quantity * price
                        category_performance[category]['quantity'] += quantity
                        if category != 'all':
                            category_performance[category]['orders'] += 1
        
        categories_list = [
            {
                'category': cat,
                'revenue': round(data['revenue'], 2),
                'orders': data['orders'],
                'quantity': data['quantity']
            }
            for cat, data in category_performance.items()
        ]
        
        # Average order value
        avg_order_value = total_revenue / delivered_orders if delivered_orders > 0 else 0
        
        # Monthly breakdown (last 12 months)
        monthly_revenue = defaultdict(float)
        monthly_orders = defaultdict(int)
        
        for order in orders:
            if order.get('payment_status') == 'paid' or order.get('status') == 'delivered':
                order_date_str = order.get('created_at')
                if order_date_str:
                    try:
                        order_date = datetime.fromisoformat(order_date_str.replace('Z', '+00:00'))
                        month_key = order_date.strftime('%Y-%m')
                        monthly_revenue[month_key] += order.get('total_amount', 0)
                        monthly_orders[month_key] += 1
                    except:
                        pass
        
        monthly_breakdown = [
            {
                'month': month,
                'revenue': round(revenue, 2),
                'orders': monthly_orders[month],
                'avg_order_value': round(revenue / monthly_orders[month], 2) if monthly_orders[month] > 0 else 0
            }
            for month, revenue in sorted(monthly_revenue.items())[-12:]
        ]
        
        return Response({
            'success': True,
            'analytics': {
                'total_revenue': round(total_revenue, 2),
                'total_orders': total_orders,
                'pending_orders': pending_orders,
                'confirmed_orders': confirmed_orders,
                'processing_orders': processing_orders,
                'shipped_orders': shipped_orders,
                'completed_orders': delivered_orders,
                'cancelled_orders': cancelled_orders,
                'avg_order_value': round(avg_order_value, 2),
                'revenue_trends': revenue_trends_list,
                'monthly_breakdown': monthly_breakdown,
                'top_products': top_products,
                'categories_performance': categories_list
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve analytics: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_dashboard_summary(request):
    """Get quick dashboard summary for seller."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Only sellers can view dashboard
    if request.user.role != 'seller':
        return Response({
            'success': False,
            'message': 'Only sellers can view dashboard'
        }, status=status.HTTP_403_FORBIDDEN)
    
    seller_id = request.user.user_id
    
    try:
        # Get recent orders (last 7 days)
        orders = MongoDBService.query_collection(
            'orders',
            filters=[('seller_id', '==', seller_id)],
            order_by='-created_at'
        )
        
        # Filter last 7 days
        seven_days_ago = datetime.now() - timedelta(days=7)
        recent_orders = []
        for order in orders:
            order_date_str = order.get('created_at')
            if order_date_str:
                try:
                    order_date = datetime.fromisoformat(order_date_str.replace('Z', '+00:00'))
                    if order_date >= seven_days_ago:
                        recent_orders.append(order)
                except:
                    pass
        
        # Quick stats
        total_products = MongoDBService.count_documents('products', [('seller_id', '==', seller_id), ('is_active', '==', True)])
        pending_orders_count = len([o for o in orders if o.get('status') == 'pending'])
        recent_revenue = sum(
            o.get('total_amount', 0) 
            for o in recent_orders 
            if o.get('payment_status') == 'paid' or o.get('status') == 'delivered'
        )
        
        # Recent orders (last 5)
        recent_orders_list = [
            {
                'order_id': o.get('order_id'),
                'buyer_id': o.get('buyer_id'),
                'total_amount': o.get('total_amount'),
                'status': o.get('status'),
                'created_at': o.get('created_at')
            }
            for o in recent_orders[:5]
        ]
        
        return Response({
            'success': True,
            'summary': {
                'total_products': total_products,
                'pending_orders': pending_orders_count,
                'recent_revenue': round(recent_revenue, 2),
                'recent_orders': recent_orders_list
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve dashboard summary: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
