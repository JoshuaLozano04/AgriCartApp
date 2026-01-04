"""
Order management views with real-time updates.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from utils.mongodb_service import MongoDBService
from utils.fcm_service import FCMService
from utils.notification_service import NotificationService
from .serializers import OrderSerializer, OrderStatusUpdateSerializer
import uuid


def send_order_notification(order_data, notification_type='status_update'):
    """Send real-time notification via WebSocket and push notification."""
    try:
        channel_layer = get_channel_layer()
        buyer_id = order_data.get('buyer_id')
        seller_id = order_data.get('seller_id')
        order_id = order_data.get('order_id')
        order_status = order_data.get('status')
        
        # Send WebSocket notification to buyer
        async_to_sync(channel_layer.group_send)(
            f'user_{buyer_id}',
            {
                'type': 'order_update',
                'order_id': order_id,
                'status': order_status,
                'message': f'Order status updated to {order_status}'
            }
        )
        
        # Send WebSocket notification to seller
        async_to_sync(channel_layer.group_send)(
            f'user_{seller_id}',
            {
                'type': 'order_update',
                'order_id': order_id,
                'status': order_status,
                'message': f'Order status updated to {order_status}'
            }
        )
        
        # Persist notifications and push if unread
        notif_svc = NotificationService()
        
        # Buyer notification (always order_update for buyer)
        notif_svc.create_notification(
            user_id=buyer_id,
            notification_type='order_update',
            title='Order Update',
            body=f'Your order #{order_id[:8]} status: {order_status}',
            data={'order_id': order_id, 'status': order_status}
        )
        notif_svc.send_unread_for_user(buyer_id)
        
        # Seller notification: order_request on new order; order_update on status changes
        if notification_type == 'new_order':
            notif_type = 'order_request'
            title = 'New Order Request'
            body = f'New order #{order_id[:8]} placed.'
        else:
            notif_type = 'order_update'
            title = 'Order Update'
            body = f'Order #{order_id[:8]} status: {order_status}'

        notif_svc.create_notification(
            user_id=seller_id,
            notification_type=notif_type,
            title=title,
            body=body,
            data={'order_id': order_id, 'status': order_status}
        )
        notif_svc.send_unread_for_user(seller_id)
    except Exception as e:
        print(f'Error sending order notification: {e}')


@api_view(['POST'])
def create_order(request):
    """Create a new order."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Only buyers can create orders
    if request.user.role != 'buyer':
        return Response({
            'success': False,
            'message': 'Only buyers can create orders'
        }, status=status.HTTP_403_FORBIDDEN)
    
    serializer = OrderSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        order_id = str(uuid.uuid4())
        buyer_id = request.user.user_id
        
        # Validate items and extract seller_id
        seller_id = None
        total_calculated = 0.0
        
        for item in data['items']:
            product = MongoDBService.get_document('products', item['product_id'])
            if not product:
                return Response({
                    'success': False,
                    'message': f'Product {item["product_id"]} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            if not product.get('is_active', False):
                return Response({
                    'success': False,
                    'message': f'Product {item["product_id"]} is not available'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if product.get('quantity', 0) < item['quantity']:
                return Response({
                    'success': False,
                    'message': f'Insufficient quantity for product {product.get("name", "Unknown")}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Verify all items are from the same seller
            item_seller_id = product.get('seller_id')
            if not seller_id:
                seller_id = item_seller_id
            elif seller_id != item_seller_id:
                return Response({
                    'success': False,
                    'message': 'All items must be from the same seller'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Calculate total
            total_calculated += item['price'] * item['quantity']
        
        # Verify total amount matches
        if abs(total_calculated - data['total_amount']) > 0.01:
            return Response({
                'success': False,
                'message': f'Total amount mismatch. Expected: {total_calculated}, Got: {data["total_amount"]}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not seller_id:
            return Response({
                'success': False,
                'message': 'Could not determine seller from products'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create order document in MongoDB
        order_data = {
            'order_id': order_id,
            'buyer_id': buyer_id,
            'seller_id': seller_id,
            'items': [dict(item) for item in data['items']],
            'shipping_address': MongoDBService.sanitize_string(data['shipping_address'], max_length=500),
            'shipping_latitude': data.get('shipping_latitude'),
            'shipping_longitude': data.get('shipping_longitude'),
            'payment_method': data['payment_method'],
            'total_amount': data['total_amount'],
            'payment_status': 'pending',
            'status': 'pending',
            'created_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        }
        
        try:
            MongoDBService.create_document('orders', order_data, order_id)
            
            # Update product quantities
            for item in data['items']:
                product = MongoDBService.get_document('products', item['product_id'])
                if product:
                    new_quantity = product.get('quantity', 0) - item['quantity']
                    MongoDBService.update_document('products', item['product_id'], {
                        'quantity': max(0, new_quantity),
                        'updated_at': 'SERVER_TIMESTAMP'
                    })
                    # Low stock notification when quantity hits exactly 5
                    try:
                        final_qty = max(0, new_quantity)
                        if final_qty == 5:
                            seller = MongoDBService.get_document('users', product.get('seller_id'))
                            if seller:
                                tokens = seller.get('fcm_tokens', [])
                                if tokens:
                                    NotificationService().create_notification(
                                        user_id=product.get('seller_id'),
                                        notification_type='low_stock',
                                        title='Low Stock Alert',
                                        body=f"{product.get('name', 'Product')} stock is down to 5",
                                        data={
                                            'product_id': product.get('product_id') or item['product_id'],
                                            'qty': '5'
                                        }
                                    )
                                    NotificationService().send_unread_for_user(product.get('seller_id'))
                    except Exception:
                        pass
            
            # Send notification to seller
            send_order_notification(order_data, 'new_order')
            
            return Response({
                'success': True,
                'message': 'Order created successfully',
                'order_id': order_id,
                'order': order_data
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
    import sys
    # Debug authentication
    print(f'DEBUG get_order: request.user type={type(request.user)}', file=sys.stderr)
    print(f'DEBUG get_order: hasattr user={hasattr(request, "user")}', file=sys.stderr)
    if hasattr(request, 'user'):
        print(f'DEBUG get_order: request.user={request.user}', file=sys.stderr)
        print(f'DEBUG get_order: hasattr user_id={hasattr(request.user, "user_id")}', file=sys.stderr)
        if hasattr(request.user, 'user_id'):
            print(f'DEBUG get_order: user_id={request.user.user_id}', file=sys.stderr)
    
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        print('DEBUG get_order: Authentication check failed', file=sys.stderr)
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    user_role = request.user.role
    
    try:
        order_data = MongoDBService.get_document('orders', order_id)
        if not order_data:
            return Response({
                'success': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Verify user has access (buyer or seller)
        if user_role == 'buyer' and order_data.get('buyer_id') != user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Order does not belong to you'
            }, status=status.HTTP_403_FORBIDDEN)
        
        if user_role == 'seller' and order_data.get('seller_id') != user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Order does not belong to you'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Enrich order with product details
        enriched_items = []
        for item in order_data.get('items', []):
            product = MongoDBService.get_document('products', item.get('product_id'))
            if product:
                enriched_items.append({
                    **item,
                    'product_name': product.get('name'),
                    'product_image': product.get('image_paths', [])[0] if product.get('image_paths') else None
                })
            else:
                enriched_items.append(item)
        
        order_data['items'] = enriched_items
        
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
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    user_id = request.user.user_id
    user_role = request.user.role
    
    try:
        filters = []
        if user_role == 'buyer':
            filters.append(('buyer_id', '==', user_id))
        elif user_role == 'seller':
            filters.append(('seller_id', '==', user_id))
        
        # Optional status filter
        status_filter = request.query_params.get('status')
        if status_filter:
            filters.append(('status', '==', status_filter))
        
        orders = MongoDBService.query_collection(
            'orders',
            filters=filters,
            order_by='-created_at'
        )
        
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
    """Update order status (seller only)."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Only sellers can update order status
    if request.user.role != 'seller':
        return Response({
            'success': False,
            'message': 'Only sellers can update order status'
        }, status=status.HTTP_403_FORBIDDEN)
    
    serializer = OrderStatusUpdateSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        new_status = data['status']
        
        # Validate status transition
        valid_transitions = {
            'pending': ['confirmed', 'cancelled'],
            'confirmed': ['processing', 'cancelled'],
            'processing': ['shipped', 'cancelled'],
            'shipped': ['delivered'],
            'delivered': [],
            'cancelled': []
        }
        
        try:
            order = MongoDBService.get_document('orders', order_id)
            if not order:
                return Response({
                    'success': False,
                    'message': 'Order not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Verify seller owns the order
            if order.get('seller_id') != request.user.user_id:
                return Response({
                    'success': False,
                    'message': 'Unauthorized: Order does not belong to this seller'
                }, status=status.HTTP_403_FORBIDDEN)
            
            current_status = order.get('status')
            if new_status not in valid_transitions.get(current_status, []):
                return Response({
                    'success': False,
                    'message': f'Invalid status transition from {current_status} to {new_status}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            update_data = {
                'status': new_status,
                'updated_at': 'SERVER_TIMESTAMP'
            }
            
            if 'tracking_number' in data and data['tracking_number']:
                update_data['tracking_number'] = MongoDBService.sanitize_string(
                    data['tracking_number'], max_length=100
                )
            
            # If order is delivered and payment method is COD, mark as paid
            if new_status == 'delivered' and order.get('payment_method') == 'cod':
                if order.get('payment_status') == 'pending':
                    update_data['payment_status'] = 'paid'
            
            # Update order
            success = MongoDBService.update_document('orders', order_id, update_data)
            if success:
                # Get updated order
                updated_order = MongoDBService.get_document('orders', order_id)
                
                # Send real-time notification
                send_order_notification(updated_order, 'status_update')
                
                # If cancelled, restore product quantities
                if new_status == 'cancelled':
                    for item in order.get('items', []):
                        product = MongoDBService.get_document('products', item.get('product_id'))
                        if product:
                            restored_quantity = product.get('quantity', 0) + item.get('quantity', 0)
                            MongoDBService.update_document('products', item.get('product_id'), {
                                'quantity': restored_quantity,
                                'updated_at': 'SERVER_TIMESTAMP'
                            })
                
                return Response({
                    'success': True,
                    'message': 'Order status updated successfully',
                    'order': updated_order
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
