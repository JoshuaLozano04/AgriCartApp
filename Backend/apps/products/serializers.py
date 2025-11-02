"""
Serializers for products app.
"""
from rest_framework import serializers


class ProductSerializer(serializers.Serializer):
    """Serializer for product."""
    product_id = serializers.CharField(required=False)
    # seller_id comes from authenticated user token
    name = serializers.CharField(max_length=255)
    description = serializers.CharField()
    category = serializers.ChoiceField(choices=[
        'fresh_produce', 'livestock_poultry', 'seeds_fertilizers',
        'farm_tools', 'processed_goods'
    ])
    price = serializers.FloatField(min_value=0)
    quantity = serializers.IntegerField(min_value=0)
    unit = serializers.CharField(max_length=50, default='piece')
    location = serializers.CharField(max_length=255)
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    image_paths = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True
    )


class ProductListSerializer(serializers.Serializer):
    """Serializer for product listing with filters."""
    category = serializers.ChoiceField(
        choices=[
            'fresh_produce', 'livestock_poultry', 'seeds_fertilizers',
            'farm_tools', 'processed_goods'
        ],
        required=False
    )
    min_price = serializers.FloatField(required=False, min_value=0)
    max_price = serializers.FloatField(required=False, min_value=0)
    location = serializers.CharField(required=False)
    search = serializers.CharField(required=False)
    seller_id = serializers.CharField(required=False)

