"""
Payment processing views.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from utils.paymongo_client import PayMongoClient
from utils.firebase_service import FirebaseService
from firebase_admin import firestore


@api_view(['POST'])
def create_payment(request):
    """Create a payment intent."""
    order_id = request.data.get('order_id')
    amount = request.data.get('amount')
    payment_method = request.data.get('payment_method', 'cod')
    
    if not order_id or not amount:
        return Response({
            'success': False,
            'message': 'order_id and amount are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        paymongo = PayMongoClient()
        
        if payment_method == 'cod':
            # Cash on Delivery - no payment processing needed
            return Response({
                'success': True,
                'message': 'COD payment confirmed',
                'payment_method': 'cod',
                'status': 'pending'
            }, status=status.HTTP_200_OK)
        else:
            # Create payment intent for online payment methods
            payment_intent = paymongo.create_payment_intent(
                amount=float(amount),
                currency='PHP',
                description=f'Order {order_id}'
            )
            
            if payment_intent:
                # Store payment info in Firestore
                payment_data = {
                    'order_id': order_id,
                    'payment_intent_id': payment_intent.get('data', {}).get('id'),
                    'amount': amount,
                    'payment_method': payment_method,
                    'status': 'pending',
                    'created_at': firestore.SERVER_TIMESTAMP
                }
                FirebaseService.create_document('payments', payment_data)
                
                return Response({
                    'success': True,
                    'payment_intent': payment_intent,
                    'payment_method': payment_method
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to create payment intent'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Payment processing failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def confirm_payment(request):
    """Confirm a payment."""
    payment_intent_id = request.data.get('payment_intent_id')
    
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
            
            # Update payment status in Firestore
            payments = FirebaseService.query_collection('payments', filters=[
                ('payment_intent_id', '==', payment_intent_id)
            ])
            
            for payment_doc in payments:
                payment_id = payment_doc.id
                FirebaseService.update_document('payments', payment_id, {
                    'status': status_value,
                    'updated_at': firestore.SERVER_TIMESTAMP
                })
            
            return Response({
                'success': True,
                'status': status_value,
                'payment_intent': payment_intent
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
