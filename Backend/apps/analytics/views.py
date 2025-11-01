"""
Analytics views for sales data and trends.
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from utils.firebase_service import FirebaseService


@api_view(['GET'])
def get_sales_analytics(request):
    """Get sales analytics for a seller."""
    seller_id = request.query_params.get('seller_id')
    
    if not seller_id:
        return Response({
            'success': False,
            'message': 'seller_id is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Get all orders for this seller
        filters = [('seller_id', '==', seller_id), ('status', '==', 'delivered')]
        orders = list(FirebaseService.query_collection('orders', filters=filters))
        
        total_revenue = sum(order.to_dict().get('total_amount', 0) for order in orders)
        total_orders = len(orders)
        
        # Get top products
        product_sales = {}
        for order in orders:
            for item in order.to_dict().get('items', []):
                product_id = item.get('product_id')
                quantity = item.get('quantity', 0)
                if product_id in product_sales:
                    product_sales[product_id] += quantity
                else:
                    product_sales[product_id] = quantity
        
        top_products = sorted(product_sales.items(), key=lambda x: x[1], reverse=True)[:10]
        
        return Response({
            'success': True,
            'analytics': {
                'total_revenue': total_revenue,
                'total_orders': total_orders,
                'top_products': [{'product_id': pid, 'quantity_sold': qty} for pid, qty in top_products]
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve analytics: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
