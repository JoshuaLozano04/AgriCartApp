"""
Order management views.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from firebase_admin import firestore
from utils.firebase_service import FirebaseService
from .serializers import OrderSerializer, OrderStatusUpdateSerializer
import uuid


@api_view(['POST'])
def create_order(request):
    """Create a new order."""
    serializer = OrderSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        order_id = str(uuid.uuid4())
        
        # Create order document in Firestore
        order_data = {
            'order_id': order_id,
            'buyer_id': data['buyer_id'],
            'seller_id': data['seller_id'],
            'items': [dict(item) for item in data['items']],
            'shipping_address': data['shipping_address'],
            'payment_method': data['payment_method'],
            'total_amount': data['total_amount'],
            'status': 'pending',
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        try:
            FirebaseService.create_document('orders', order_data, order_id)
            
            # Update product quantities
            for item in data['items']:
                product_doc = FirebaseService.get_document('products', item['product_id'])
                if product_doc:
                    product_data = product_doc.to_dict()
                    new_quantity = product_data.get('quantity', 0) - item['quantity']
                    FirebaseService.update_document('products', item['product_id'], {
                        'quantity': max(0, new_quantity),
                        'updated_at': firestore.SERVER_TIMESTAMP
                    })
            
            return Response({
                'success': True,
                'message': 'Order created successfully',
                'order_id': order_id
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to create order: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_order(request, order_id):
    """Get order details."""
    try:
        order_doc = FirebaseService.get_document('orders', order_id)
        if not order_doc:
            return Response({
                'success': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        order_data = order_doc.to_dict()
        
        # Convert timestamps
        if 'created_at' in order_data:
            order_data['created_at'] = order_data['created_at'].isoformat() if hasattr(order_data['created_at'], 'isoformat') else str(order_data['created_at'])
        if 'updated_at' in order_data:
            order_data['updated_at'] = order_data['updated_at'].isoformat() if hasattr(order_data['updated_at'], 'isoformat') else str(order_data['updated_at'])
        
        return Response({
            'success': True,
            'order': order_data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve order: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def list_orders(request):
    """List orders for a buyer or seller."""
    user_id = request.query_params.get('user_id')
    user_role = request.query_params.get('role')  # 'buyer' or 'seller'
    
    if not user_id or not user_role:
        return Response({
            'success': False,
            'message': 'user_id and role are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        filters = []
        if user_role == 'buyer':
            filters.append(('buyer_id', '==', user_id))
        elif user_role == 'seller':
            filters.append(('seller_id', '==', user_id))
        
        orders = []
        query_results = FirebaseService.query_collection('orders', filters=filters)
        
        for doc in query_results:
            order_data = doc.to_dict()
            if 'created_at' in order_data:
                order_data['created_at'] = order_data['created_at'].isoformat() if hasattr(order_data['created_at'], 'isoformat') else str(order_data['created_at'])
            if 'updated_at' in order_data:
                order_data['updated_at'] = order_data['updated_at'].isoformat() if hasattr(order_data['updated_at'], 'isoformat') else str(order_data['updated_at'])
            orders.append(order_data)
        
        return Response({
            'success': True,
            'orders': orders,
            'count': len(orders)
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve orders: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
def update_order_status(request, order_id):
    """Update order status."""
    serializer = OrderStatusUpdateSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        
        update_data = {
            'status': data['status'],
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        if 'tracking_number' in data and data['tracking_number']:
            update_data['tracking_number'] = data['tracking_number']
        
        try:
            success = FirebaseService.update_document('orders', order_id, update_data)
            if success:
                return Response({
                    'success': True,
                    'message': 'Order status updated successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to update order status'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Update failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
