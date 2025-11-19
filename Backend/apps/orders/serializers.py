"""
Serializers for orders app.
"""
from rest_framework import serializers


class OrderItemSerializer(serializers.Serializer):
    """Serializer for order item."""
    product_id = serializers.CharField()
    quantity = serializers.IntegerField(min_value=1)
    price = serializers.FloatField(min_value=0)


class OrderSerializer(serializers.Serializer):
    """Serializer for order creation."""
    # buyer_id comes from authenticated user token
    # seller_id will be extracted from items' products
    items = OrderItemSerializer(many=True)
    shipping_address = serializers.CharField()
    payment_method = serializers.ChoiceField(choices=['cod', 'gcash'])
    total_amount = serializers.FloatField(min_value=0)


class OrderStatusUpdateSerializer(serializers.Serializer):
    """Serializer for order status update."""
    status = serializers.ChoiceField(choices=[
        'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
    ])
    tracking_number = serializers.CharField(required=False, allow_blank=True)

