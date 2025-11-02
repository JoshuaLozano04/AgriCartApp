"""
Payment processing views with PayMongo integration.
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import render
from utils.paymongo_client import PayMongoClient
from utils.mongodb_service import MongoDBService
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from utils.fcm_service import FCMService
import uuid


def send_payment_notification(order_id, payment_status, user_id):
    """Send payment notification."""
    try:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'user_{user_id}',
            {
                'type': 'payment_update',
                'order_id': order_id,
                'payment_status': payment_status,
                'message': f'Payment status: {payment_status}'
            }
        )
        
        user = MongoDBService.get_document('users', user_id)
        if user:
            device_tokens = user.get('fcm_tokens', [])
            if device_tokens:
                fcm_service = FCMService()
                fcm_service.send_multicast_notification(
                    device_tokens,
                    'Payment Update',
                    f'Payment for order #{order_id[:8]}: {payment_status}',
                    {'type': 'payment_update', 'order_id': order_id, 'status': payment_status}
                )
    except Exception as e:
        print(f'Error sending payment notification: {e}')


@api_view(['POST'])
def create_payment(request):
    """Create a payment for an order."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    order_id = request.data.get('order_id')
    payment_method = request.data.get('payment_method', 'cod')
    
    if not order_id:
        return Response({
            'success': False,
            'message': 'order_id is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate payment method
    valid_methods = ['cod', 'gcash', 'bank_transfer']
    if payment_method not in valid_methods:
        return Response({
            'success': False,
            'message': f'Invalid payment method. Must be one of: {", ".join(valid_methods)}'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Get order
        order = MongoDBService.get_document('orders', order_id)
        if not order:
            return Response({
                'success': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Verify user owns the order (buyer)
        if order.get('buyer_id') != request.user.user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Order does not belong to you'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Check if payment already exists
        existing_payments = MongoDBService.query_collection(
            'payments',
            filters=[('order_id', '==', order_id)],
            limit=1
        )
        
        if existing_payments:
            return Response({
                'success': False,
                'message': 'Payment already exists for this order'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        amount = order.get('total_amount')
        
        if payment_method == 'cod':
            # Cash on Delivery - no payment processing needed
            payment_id = str(uuid.uuid4())
            payment_data = {
                'payment_id': payment_id,
                'order_id': order_id,
                'amount': amount,
                'payment_method': 'cod',
                'status': 'pending',  # Will be confirmed when order is delivered
                'payment_intent_id': None,
                'created_at': 'SERVER_TIMESTAMP',
                'updated_at': 'SERVER_TIMESTAMP'
            }
            
            MongoDBService.create_document('payments', payment_data, payment_id)
            
            # Update order payment status
            MongoDBService.update_document('orders', order_id, {
                'payment_status': 'pending',
                'payment_method': 'cod',
                'updated_at': 'SERVER_TIMESTAMP'
            })
            
            return Response({
                'success': True,
                'message': 'COD payment created. Payment will be collected on delivery.',
                'payment_id': payment_id,
                'payment_method': 'cod',
                'status': 'pending'
            }, status=status.HTTP_201_CREATED)
        else:
            # Create payment source for online payment methods (provides checkout URL)
            paymongo = PayMongoClient()
            
            # Map payment method to PayMongo source type
            paymongo_type_map = {
                'gcash': 'gcash',
                'bank_transfer': 'dob'
            }
            paymongo_type = paymongo_type_map.get(payment_method, 'gcash')
            
            # Create payment source which provides checkout URL
            # Build redirect URLs to payment result pages with order context
            base_url = request.build_absolute_uri('/').rstrip('/')
            # Remove /api from base_url if present for payment pages
            if base_url.endswith('/api'):
                base_url = base_url[:-4]
            
            # Create payment_id first so we can include it in redirect URLs
            payment_id = str(uuid.uuid4())
            final_success_url = f"{base_url}/payment/success/?order_id={order_id}&payment_id={payment_id}"
            final_failed_url = f"{base_url}/payment/failed/?order_id={order_id}&payment_id={payment_id}"
            
            try:
                
                payment_source = paymongo.create_source(
                    amount=float(amount),
                    currency='PHP',
                    type=paymongo_type,
                    success_url=final_success_url,
                    failed_url=final_failed_url
                )
                
                if payment_source:
                    source_data = payment_source.get('data', {})
                    source_id = source_data.get('id')
                    source_attributes = source_data.get('attributes', {})
                    redirect_data = source_attributes.get('redirect', {})
                    checkout_url = redirect_data.get('checkout_url') if redirect_data else None
                    
                    if not checkout_url:
                        print(f"DEBUG: No checkout_url in source response. Full response: {payment_source}")
                        return Response({
                            'success': False,
                            'message': 'Payment source created but no checkout URL received from PayMongo'
                        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                    
                    # payment_id already created above
                    payment_data = {
                        'payment_id': payment_id,
                        'order_id': order_id,
                        'amount': amount,
                        'payment_method': payment_method,
                        'status': 'pending',
                        'payment_source_id': source_id,
                        'payment_url': checkout_url,
                        'created_at': 'SERVER_TIMESTAMP',
                        'updated_at': 'SERVER_TIMESTAMP'
                    }
                    
                    MongoDBService.create_document('payments', payment_data, payment_id)
                    
                    # Update order payment status
                    MongoDBService.update_document('orders', order_id, {
                        'payment_status': 'pending',
                        'payment_method': payment_method,
                        'payment_source_id': source_id,
                        'updated_at': 'SERVER_TIMESTAMP'
                    })
                    
                    # Return our branded redirect page URL instead of direct PayMongo URL
                    from urllib.parse import quote
                    encoded_checkout_url = quote(checkout_url, safe='')
                    redirect_page_url = f"{base_url}/payment/redirect/?checkout_url={encoded_checkout_url}&order_id={order_id}&payment_id={payment_id}"
                    
                    return Response({
                        'success': True,
                        'payment_id': payment_id,
                        'payment_source_id': source_id,
                        'payment_url': redirect_page_url,  # Our branded redirect page
                        'payment_method': payment_method,
                        'status': 'pending'
                    }, status=status.HTTP_201_CREATED)
                else:
                    return Response({
                        'success': False,
                        'message': 'Failed to create payment source with PayMongo. Please check your PayMongo API keys and configuration.'
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            except Exception as e:
                import traceback
                print(f"ERROR creating payment source: {str(e)}")
                traceback.print_exc()
                return Response({
                    'success': False,
                    'message': f'Error creating payment: {str(e)}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Payment processing failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def confirm_payment(request):
    """Confirm a payment (check status with PayMongo)."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    payment_intent_id = request.data.get('payment_intent_id')
    order_id = request.data.get('order_id')
    
    if not payment_intent_id:
        return Response({
            'success': False,
            'message': 'payment_intent_id is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        paymongo = PayMongoClient()
        payment_intent = paymongo.retrieve_payment_intent(payment_intent_id)
        
        if payment_intent:
            status_value = payment_intent.get('data', {}).get('attributes', {}).get('status')
            
            # Find payment record
            payments = MongoDBService.query_collection('payments', filters=[
                ('payment_intent_id', '==', payment_intent_id)
            ])
            
            if not payments:
                return Response({
                    'success': False,
                    'message': 'Payment record not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            payment = payments[0]
            payment_id = payment.get('_id') or payment.get('payment_id')
            order_id = payment.get('order_id')
            
            # Update payment status
            MongoDBService.update_document('payments', payment_id, {
                'status': status_value,
                'updated_at': 'SERVER_TIMESTAMP'
            })
            
            # Update order payment status
            order_update = {'payment_status': status_value}
            if status_value == 'succeeded':
                order_update['payment_status'] = 'paid'
            
            MongoDBService.update_document('orders', order_id, {
                **order_update,
                'updated_at': 'SERVER_TIMESTAMP'
            })
            
            # Send notification
            order = MongoDBService.get_document('orders', order_id)
            if order:
                send_payment_notification(order_id, status_value, order.get('buyer_id'))
            
            return Response({
                'success': True,
                'status': status_value,
                'payment_intent': payment_intent,
                'order_id': order_id
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': 'Payment intent not found'
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to confirm payment: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_payment(request, order_id):
    """Get payment details for an order."""
    # Check authentication
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    try:
        # Get order first to verify ownership
        order = MongoDBService.get_document('orders', order_id)
        if not order:
            return Response({
                'success': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Verify user has access
        if order.get('buyer_id') != request.user.user_id and order.get('seller_id') != request.user.user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Get payment
        payments = MongoDBService.query_collection(
            'payments',
            filters=[('order_id', '==', order_id)],
            limit=1
        )
        
        if not payments:
            return Response({
                'success': False,
                'message': 'Payment not found for this order'
            }, status=status.HTTP_404_NOT_FOUND)
        
        payment = payments[0]
        
        return Response({
            'success': True,
            'payment': payment
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve payment: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def payment_redirect(request):
    """Show branded redirect page before going to PayMongo checkout."""
    try:
        from urllib.parse import unquote
        checkout_url = unquote(request.GET.get('checkout_url', ''))
        order_id = request.GET.get('order_id', '')
        payment_id = request.GET.get('payment_id', '')
        
        # Get order details if order_id is provided
        order_data = None
        if order_id:
            try:
                order_data = MongoDBService.get_document('orders', order_id)
            except Exception as e:
                print(f"DEBUG payment_redirect: Error fetching order {order_id}: {e}")
                pass
        
        context = {
            'checkout_url': checkout_url,
            'order_id': order_id,
            'payment_id': payment_id,
            'order': order_data,
        }
        
        return render(request, 'payments/redirect.html', context)
    except Exception as e:
        import traceback
        print(f"ERROR payment_redirect: {str(e)}")
        traceback.print_exc()
        from django.http import HttpResponse
        return HttpResponse(f"<h1>Redirecting...</h1><p>Error: {str(e)}</p><script>window.location.href='{checkout_url}';</script>", status=500)


def payment_success(request):
    """Render payment success page and verify payment status."""
    try:
        order_id = request.GET.get('order_id', '')
        payment_id = request.GET.get('payment_id', '')
        # PayMongo may include source ID in query params when redirecting
        source_id = request.GET.get('id', '')  # PayMongo redirects with ?id=source_id
        
        # Try to get order details if order_id is provided
        order_data = None
        if order_id:
            try:
                order_data = MongoDBService.get_document('orders', order_id)
            except Exception as e:
                print(f"DEBUG payment_success: Error fetching order {order_id}: {e}")
                pass
        
        # Verify payment status with PayMongo if we have source_id or payment_id
        if order_id and (source_id or payment_id):
            try:
                paymongo = PayMongoClient()
                
                # Try to get source_id from payment record if not in URL
                if not source_id and payment_id:
                    try:
                        payment_data = MongoDBService.get_document('payments', payment_id)
                        source_id = payment_data.get('payment_source_id') if payment_data else None
                    except:
                        pass
                
                # Retrieve source status from PayMongo
                if source_id:
                    source_data = paymongo.retrieve_source(source_id)
                    
                    if source_data:
                        source_attributes = source_data.get('data', {}).get('attributes', {})
                        source_status = source_attributes.get('status', '')
                        
                        print(f"DEBUG payment_success: Source {source_id} status: {source_status}")
                        
                        # Map PayMongo source status to our payment status
                        # PayMongo source statuses: pending, chargeable, failed, cancelled
                        # When user completes payment, source becomes "chargeable"
                        # Then we need to create a payment from the source
                        if source_status == 'chargeable':
                            # Source is ready to be charged - payment was successful
                            payment_status = 'paid'
                            order_payment_status = 'paid'
                            
                            # Update payment record
                            if payment_id:
                                try:
                                    MongoDBService.update_document('payments', payment_id, {
                                        'status': payment_status,
                                        'updated_at': 'SERVER_TIMESTAMP'
                                    })
                                except Exception as e:
                                    print(f"DEBUG payment_success: Error updating payment {payment_id}: {e}")
                            
                            # Update order payment status
                            if order_id:
                                try:
                                    MongoDBService.update_document('orders', order_id, {
                                        'payment_status': order_payment_status,
                                        'updated_at': 'SERVER_TIMESTAMP'
                                    })
                                    # Send notification
                                    if order_data:
                                        send_payment_notification(order_id, payment_status, order_data.get('buyer_id'))
                                except Exception as e:
                                    print(f"DEBUG payment_success: Error updating order {order_id}: {e}")
                        
                        elif source_status == 'failed':
                            # Payment failed
                            payment_status = 'failed'
                            order_payment_status = 'failed'
                            
                            if payment_id:
                                try:
                                    MongoDBService.update_document('payments', payment_id, {
                                        'status': payment_status,
                                        'updated_at': 'SERVER_TIMESTAMP'
                                    })
                                except Exception as e:
                                    print(f"DEBUG payment_success: Error updating payment {payment_id}: {e}")
                            
                            if order_id:
                                try:
                                    MongoDBService.update_document('orders', order_id, {
                                        'payment_status': order_payment_status,
                                        'updated_at': 'SERVER_TIMESTAMP'
                                    })
                                except Exception as e:
                                    print(f"DEBUG payment_success: Error updating order {order_id}: {e}")
                        
                        # Refresh order data after update
                        try:
                            order_data = MongoDBService.get_document('orders', order_id)
                        except:
                            pass
            except Exception as e:
                print(f"DEBUG payment_success: Error verifying payment with PayMongo: {e}")
                import traceback
                traceback.print_exc()
        
        context = {
            'order_id': order_id,
            'payment_id': payment_id,
            'order': order_data,
        }
        
        return render(request, 'payments/success.html', context)
    except Exception as e:
        import traceback
        print(f"ERROR payment_success: {str(e)}")
        traceback.print_exc()
        # Return a simple error page if template rendering fails
        from django.http import HttpResponse
        return HttpResponse(f"<h1>Payment Success</h1><p>Order ID: {order_id}</p><p>Error: {str(e)}</p>", status=500)


def payment_failed(request):
    """Render payment failed page."""
    try:
        order_id = request.GET.get('order_id', '')
        payment_id = request.GET.get('payment_id', '')
        error_message = request.GET.get('error', 'Payment was not completed successfully.')
        
        # Try to get order details if order_id is provided
        order_data = None
        if order_id:
            try:
                order_data = MongoDBService.get_document('orders', order_id)
            except Exception as e:
                print(f"DEBUG payment_failed: Error fetching order {order_id}: {e}")
                pass
        
        context = {
            'order_id': order_id,
            'payment_id': payment_id,
            'error_message': error_message,
            'order': order_data,
        }
        
        return render(request, 'payments/failed.html', context)
    except Exception as e:
        import traceback
        print(f"ERROR payment_failed: {str(e)}")
        traceback.print_exc()
        # Return a simple error page if template rendering fails
        from django.http import HttpResponse
        return HttpResponse(f"<h1>Payment Failed</h1><p>Order ID: {order_id}</p><p>Error: {str(e)}</p>", status=500)
