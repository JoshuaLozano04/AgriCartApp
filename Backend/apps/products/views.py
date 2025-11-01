"""
Product CRUD views with MongoDB GridFS image handling.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from firebase_admin import firestore
from utils.firebase_service import FirebaseService
from utils.mongodb import MongoDBService
from .serializers import ProductSerializer, ProductListSerializer
import uuid
import base64


@api_view(['POST'])
def create_product(request):
    """Create a new product."""
    serializer = ProductSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        product_id = str(uuid.uuid4())
        seller_id = data['seller_id']
        
        # Handle image uploads if provided
        image_ids = []
        if 'images' in request.FILES:
            mongodb = MongoDBService()
            for image_file in request.FILES.getlist('images'):
                image_data = image_file.read()
                image_id = mongodb.upload_image(
                    image_data,
                    filename=image_file.name,
                    content_type=image_file.content_type
                )
                image_ids.append(image_id)
            mongodb.close()
        elif 'image_ids' in data:
            image_ids = data['image_ids']
        
        # Create product document in Firestore
        product_data = {
            'product_id': product_id,
            'seller_id': seller_id,
            'name': data['name'],
            'description': data['description'],
            'category': data['category'],
            'price': data['price'],
            'quantity': data['quantity'],
            'unit': data.get('unit', 'piece'),
            'location': data['location'],
            'latitude': data.get('latitude'),
            'longitude': data.get('longitude'),
            'image_ids': image_ids,
            'is_active': True,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        try:
            FirebaseService.create_document('products', product_data, product_id)
            return Response({
                'success': True,
                'message': 'Product created successfully',
                'product_id': product_id
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to create product: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
def list_products(request):
    """List products with optional filters."""
    serializer = ProductListSerializer(data=request.query_params)
    if serializer.is_valid():
        filters = []
        
        # Category filter
        if 'category' in serializer.validated_data:
            filters.append(('category', '==', serializer.validated_data['category']))
        
        # Seller filter
        if 'seller_id' in serializer.validated_data:
            filters.append(('seller_id', '==', serializer.validated_data['seller_id']))
        
        # Active products only
        filters.append(('is_active', '==', True))
        
        try:
            products = []
            query_results = FirebaseService.query_collection('products', filters=filters)
            
            for doc in query_results:
                product_data = doc.to_dict()
                
                # Apply price filter if provided
                if 'min_price' in serializer.validated_data:
                    if product_data.get('price', 0) < serializer.validated_data['min_price']:
                        continue
                if 'max_price' in serializer.validated_data:
                    if product_data.get('price', 0) > serializer.validated_data['max_price']:
                        continue
                
                # Apply location filter if provided
                if 'location' in serializer.validated_data:
                    location_filter = serializer.validated_data['location'].lower()
                    if location_filter not in product_data.get('location', '').lower():
                        continue
                
                # Apply search filter if provided
                if 'search' in serializer.validated_data:
                    search_term = serializer.validated_data['search'].lower()
                    if search_term not in product_data.get('name', '').lower() and \
                       search_term not in product_data.get('description', '').lower():
                        continue
                
                # Convert timestamps
                if 'created_at' in product_data:
                    product_data['created_at'] = product_data['created_at'].isoformat() if hasattr(product_data['created_at'], 'isoformat') else str(product_data['created_at'])
                if 'updated_at' in product_data:
                    product_data['updated_at'] = product_data['updated_at'].isoformat() if hasattr(product_data['updated_at'], 'isoformat') else str(product_data['updated_at'])
                
                products.append(product_data)
            
            return Response({
                'success': True,
                'products': products,
                'count': len(products)
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to retrieve products: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_product(request, product_id):
    """Get a single product by ID."""
    try:
        product_doc = FirebaseService.get_document('products', product_id)
        if not product_doc:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        product_data = product_doc.to_dict()
        
        # Convert timestamps
        if 'created_at' in product_data:
            product_data['created_at'] = product_data['created_at'].isoformat() if hasattr(product_data['created_at'], 'isoformat') else str(product_data['created_at'])
        if 'updated_at' in product_data:
            product_data['updated_at'] = product_data['updated_at'].isoformat() if hasattr(product_data['updated_at'], 'isoformat') else str(product_data['updated_at'])
        
        return Response({
            'success': True,
            'product': product_data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve product: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
def update_product(request, product_id):
    """Update a product."""
    serializer = ProductSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        
        # Check if product exists and belongs to seller
        product_doc = FirebaseService.get_document('products', product_id)
        if not product_doc:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        product_data = product_doc.to_dict()
        if product_data.get('seller_id') != data.get('seller_id'):
            return Response({
                'success': False,
                'message': 'Unauthorized: Product does not belong to this seller'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Handle image uploads if provided
        if 'images' in request.FILES:
            mongodb = MongoDBService()
            image_ids = []
            for image_file in request.FILES.getlist('images'):
                image_data = image_file.read()
                image_id = mongodb.upload_image(
                    image_data,
                    filename=image_file.name,
                    content_type=image_file.content_type
                )
                image_ids.append(image_id)
            data['image_ids'] = image_ids
            mongodb.close()
        
        # Prepare update data
        update_data = {}
        for key in ['name', 'description', 'category', 'price', 'quantity', 'unit', 'location', 'latitude', 'longitude', 'image_ids']:
            if key in data:
                update_data[key] = data[key]
        
        update_data['updated_at'] = firestore.SERVER_TIMESTAMP
        
        try:
            success = FirebaseService.update_document('products', product_id, update_data)
            if success:
                return Response({
                    'success': True,
                    'message': 'Product updated successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to update product'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Update failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def delete_product(request, product_id):
    """Delete a product (soft delete)."""
    try:
        product_doc = FirebaseService.get_document('products', product_id)
        if not product_doc:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Soft delete by setting is_active to False
        FirebaseService.update_document('products', product_id, {
            'is_active': False,
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        return Response({
            'success': True,
            'message': 'Product deleted successfully'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to delete product: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_image(request, image_id):
    """Get product image from MongoDB GridFS."""
    try:
        mongodb = MongoDBService()
        image_data = mongodb.get_image(image_id)
        metadata = mongodb.get_image_metadata(image_id)
        mongodb.close()
        
        if image_data and metadata:
            from django.http import HttpResponse
            response = HttpResponse(image_data, content_type=metadata.get('content_type', 'image/jpeg'))
            return response
        else:
            return Response({
                'success': False,
                'message': 'Image not found'
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve image: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
