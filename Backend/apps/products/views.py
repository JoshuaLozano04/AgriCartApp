"""
Product CRUD views with Django media file handling.
"""
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from utils.mongodb_service import MongoDBService
from .serializers import ProductSerializer, ProductListSerializer
import uuid
import os


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def create_product(request):
    """Create a new product."""
    print(f"DEBUG create_product: Request method: {request.method}")
    print(f"DEBUG create_product: Content-Type: {request.content_type}")
    print(f"DEBUG create_product: Content-Type header: {request.META.get('CONTENT_TYPE', 'NOT SET')}")
    print(f"DEBUG create_product: FILES keys: {list(request.FILES.keys())}")
    print(f"DEBUG create_product: FILES count: {len(request.FILES)}")
    print(f"DEBUG create_product: request.FILES type: {type(request.FILES)}")
    print(f"DEBUG create_product: request.data type: {type(request.data)}")
    print(f"DEBUG create_product: POST data keys: {list(request.data.keys()) if hasattr(request.data, 'keys') else 'N/A'}")
    print(f"DEBUG create_product: Has 'images' in request.FILES: {'images' in request.FILES}")
    print(f"DEBUG create_product: Has 'images' in request.data: {'images' in request.data if hasattr(request.data, '__contains__') else 'N/A'}")
    
    # Check authentication - ensure it's our SimpleUser, not AnonymousUser
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        print("DEBUG create_product: Authentication failed - no user")
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    print(f"DEBUG create_product: Authenticated user: {request.user.user_id}, role: {request.user.role}")
    
    # Only sellers can create products
    if request.user.role != 'seller':
        print(f"DEBUG create_product: Access denied - user role is {request.user.role}, not seller")
        return Response({
            'success': False,
            'message': 'Only sellers can create products'
        }, status=status.HTTP_403_FORBIDDEN)
    
    # For multipart requests, use request.data directly
    # DRF's MultiPartParser puts form fields in request.data and files in request.FILES
    # The serializer only needs form fields, not files
    serializer = ProductSerializer(data=request.data)
    if serializer.is_valid():
        print("DEBUG create_product: Serializer is valid")
        data = serializer.validated_data
        product_id = str(uuid.uuid4())
        seller_id = request.user.user_id  # Get from authenticated user
        
        # Handle image uploads - save to Django media files
        image_paths = []
        
        # Check both request.FILES and request.data for images (DRF sometimes puts files in request.data)
        image_files = []
        
        if 'images' in request.FILES:
            image_files = request.FILES.getlist('images')
            print(f"DEBUG: Found images in request.FILES: {len(image_files)} file(s)")
        elif 'images' in request.data:
            # Sometimes DRF puts files in request.data
            files = request.data.getlist('images') if hasattr(request.data, 'getlist') else [request.data.get('images')]
            image_files = [f for f in files if f]
            print(f"DEBUG: Found images in request.data: {len(image_files)} file(s)")
        else:
            print(f"DEBUG: WARNING - No 'images' found in request.FILES or request.data")
            print(f"DEBUG: Available FILES keys: {list(request.FILES.keys())}")
            print(f"DEBUG: Available data keys: {list(request.data.keys()) if hasattr(request.data, 'keys') else 'N/A'}")
        
        if image_files:
            print(f"DEBUG: Processing {len(image_files)} image file(s)")
            
            # Ensure uploads/products directory exists
            products_dir = os.path.join(settings.MEDIA_ROOT, 'uploads', 'products')
            os.makedirs(products_dir, exist_ok=True)
            
            for idx, image_file in enumerate(image_files):
                try:
                    print(f"DEBUG: Processing image {idx + 1}/{len(image_files)}")
                    print(f"DEBUG:   - File type: {type(image_file)}")
                    print(f"DEBUG:   - File name: {getattr(image_file, 'name', 'NO NAME')}")
                    print(f"DEBUG:   - Content type: {getattr(image_file, 'content_type', 'NO CONTENT TYPE')}")
                    print(f"DEBUG:   - File size: {getattr(image_file, 'size', 'UNKNOWN')}")
                    
                    # Validate file is an image
                    # Check both content_type and file extension
                    content_type = getattr(image_file, 'content_type', None)
                    file_name = getattr(image_file, 'name', '')
                    file_ext = os.path.splitext(file_name)[1].lower()
                    
                    # Check if content_type is an image type
                    is_image_by_type = content_type and content_type.startswith('image/')
                    
                    # Check if file extension suggests it's an image
                    valid_image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
                    is_image_by_ext = file_ext in valid_image_extensions
                    
                    if not is_image_by_type and not is_image_by_ext:
                        print(f"DEBUG: Skipping non-image file: {file_name} (content_type: {content_type}, extension: {file_ext})")
                        continue
                    
                    # If content_type is missing but extension is valid, proceed anyway
                    if not is_image_by_type and is_image_by_ext:
                        print(f"DEBUG: Content type missing/wrong ({content_type}), but valid image extension ({file_ext}), proceeding...")
                    
                    # Generate unique filename
                    file_ext = os.path.splitext(image_file.name)[1] or '.jpg'
                    unique_filename = f"{uuid.uuid4()}{file_ext}"
                    
                    # Read file content
                    image_file.seek(0)  # Ensure we're at the beginning of the file
                    file_content = image_file.read()
                    
                    # Save to media/uploads/products/
                    media_path = f"uploads/products/{unique_filename}"
                    saved_path = default_storage.save(media_path, ContentFile(file_content))
                    
                    # Construct full URL path that can be accessed via HTTP
                    # saved_path is relative to MEDIA_ROOT, so we prepend MEDIA_URL
                    # This creates a path like: /media/uploads/products/{filename}
                    # The Django static file serving will make it accessible at:
                    # http://server:port/media/uploads/products/{filename}
                    image_url = f"{settings.MEDIA_URL}{saved_path}"
                    image_paths.append(image_url)
                    print(f"DEBUG: Successfully saved image")
                    print(f"DEBUG:   - File saved to: {os.path.join(settings.MEDIA_ROOT, saved_path)}")
                    print(f"DEBUG:   - Saved path (relative): {saved_path}")
                    print(f"DEBUG:   - Image URL stored: {image_url}")
                    print(f"DEBUG:   - Full URL would be: http://{request.get_host()}{image_url}")
                except Exception as e:
                    print(f"ERROR: Failed to save image {image_file.name}: {str(e)}")
                    import traceback
                    traceback.print_exc()
                    # Continue with other images even if one fails
        elif 'image_paths' in data:
            image_paths = data['image_paths']
        
        print(f"DEBUG: ===== FINAL IMAGE PATHS ======")
        print(f"DEBUG: Total image_paths: {len(image_paths)}")
        for idx, img_path in enumerate(image_paths):
            print(f"DEBUG:   Image {idx + 1}: {img_path}")
        print(f"DEBUG: ==============================")
        
        # Create product document in MongoDB
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
            'image_paths': image_paths,  # This MUST be included
            'is_active': True,
            'created_at': 'SERVER_TIMESTAMP',
            'updated_at': 'SERVER_TIMESTAMP'
        }
        
        print(f"DEBUG: Product data being saved to MongoDB:")
        print(f"DEBUG:   - product_id: {product_data['product_id']}")
        print(f"DEBUG:   - name: {product_data['name']}")
        print(f"DEBUG:   - image_paths: {product_data['image_paths']}")
        print(f"DEBUG:   - image_paths type: {type(product_data['image_paths'])}")
        print(f"DEBUG:   - image_paths length: {len(product_data['image_paths'])}")
        
        try:
            MongoDBService.create_document('products', product_data, product_id)
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
    
    print(f"DEBUG create_product: Serializer validation failed")
    print(f"DEBUG create_product: Serializer errors: {serializer.errors}")
    print(f"DEBUG create_product: Request data keys: {list(request.data.keys()) if hasattr(request.data, 'keys') else 'N/A'}")
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
            # Build MongoDB query with price filters if needed
            if 'min_price' in serializer.validated_data:
                filters.append(('price', '>=', serializer.validated_data['min_price']))
            if 'max_price' in serializer.validated_data:
                filters.append(('price', '<=', serializer.validated_data['max_price']))
            
            # Get products from MongoDB
            products = MongoDBService.query_collection(
                'products',
                filters=filters,
                order_by='-created_at'  # Latest first
            )
            
            # Apply text-based filters that MongoDBService doesn't handle directly
            filtered_products = []
            for product_data in products:
                # Apply location filter if provided
                if 'location' in serializer.validated_data:
                    location_filter = serializer.validated_data['location'].lower()
                    if location_filter not in product_data.get('location', '').lower():
                        continue
                
                # Apply search filter if provided (search in name and description)
                if 'search' in serializer.validated_data:
                    search_term = serializer.validated_data['search'].lower()
                    name_match = search_term in product_data.get('name', '').lower()
                    desc_match = search_term in product_data.get('description', '').lower()
                    if not (name_match or desc_match):
                        continue
                
                filtered_products.append(product_data)
            
            return Response({
                'success': True,
                'products': filtered_products,
                'count': len(filtered_products)
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
        product_data = MongoDBService.get_document('products', product_id)
        if not product_data:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Timestamps are already converted to ISO strings by MongoDBService
        
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
@parser_classes([MultiPartParser, FormParser, JSONParser])
def update_product(request, product_id):
    """Update a product."""
    # Check authentication - ensure it's our SimpleUser, not AnonymousUser
    if not hasattr(request, 'user') or not request.user or not hasattr(request.user, 'user_id'):
        return Response({
            'success': False,
            'message': 'Authentication required'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Handle multipart form data - parse JSON strings if needed
    serializer_data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
    
    # If image_paths is a JSON string, parse it
    if 'image_paths' in serializer_data:
        image_paths_value = serializer_data['image_paths']
        if isinstance(image_paths_value, str):
            try:
                import json as json_lib
                serializer_data['image_paths'] = json_lib.loads(image_paths_value)
            except (ValueError, TypeError):
                # Not valid JSON, keep as is
                pass
    
    serializer = ProductSerializer(data=serializer_data)
    if serializer.is_valid():
        data = serializer.validated_data
        
        # Check if product exists and belongs to seller
        product_data = MongoDBService.get_document('products', product_id)
        if not product_data:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Verify seller owns the product using authenticated user's ID
        if product_data.get('seller_id') != request.user.user_id:
            return Response({
                'success': False,
                'message': 'Unauthorized: Product does not belong to this seller'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Handle image uploads - save new images and merge with existing if needed
        existing_image_paths = product_data.get('image_paths', [])
        new_image_paths = []
        
        # Check for new images being uploaded
        if 'images' in request.FILES:
            image_files = request.FILES.getlist('images')
            print(f"DEBUG Update: Received {len(image_files)} new image file(s)")
            
            # Ensure uploads/products directory exists
            products_dir = os.path.join(settings.MEDIA_ROOT, 'uploads', 'products')
            os.makedirs(products_dir, exist_ok=True)
            
            for image_file in image_files:
                try:
                    # Validate file is an image
                    content_type = getattr(image_file, 'content_type', None)
                    if not content_type or not content_type.startswith('image/'):
                        print(f"DEBUG Update: Skipping non-image file: {getattr(image_file, 'name', 'unknown')}")
                        continue
                    
                    # Generate unique filename
                    file_ext = os.path.splitext(image_file.name)[1] or '.jpg'
                    unique_filename = f"{uuid.uuid4()}{file_ext}"
                    
                    # Read file content
                    image_file.seek(0)
                    file_content = image_file.read()
                    
                    # Save to media/uploads/products/
                    media_path = f"uploads/products/{unique_filename}"
                    saved_path = default_storage.save(media_path, ContentFile(file_content))
                    
                    # Construct full URL path
                    image_url = f"{settings.MEDIA_URL}{saved_path}"
                    new_image_paths.append(image_url)
                    print(f"DEBUG Update: Successfully saved new image: {saved_path} -> {image_url}")
                except Exception as e:
                    print(f"ERROR Update: Failed to save image {image_file.name}: {str(e)}")
                    import traceback
                    traceback.print_exc()
        
        # Determine final image_paths:
        # 1. If image_paths is in data, use it as base (user may have removed some existing images)
        # 2. Add any new images uploaded
        # 3. If no image_paths in data and no new images, keep existing
        if 'image_paths' in data and isinstance(data['image_paths'], list):
            # Use provided image_paths as base (may have removed some)
            base_image_paths = data['image_paths']
            # Merge with new images if any
            if new_image_paths:
                final_image_paths = base_image_paths + new_image_paths
                print(f"DEBUG Update: Base {len(base_image_paths)} images from data + {len(new_image_paths)} new = {len(final_image_paths)} total")
            else:
                final_image_paths = base_image_paths
                print(f"DEBUG Update: Using image_paths from data: {len(final_image_paths)} images (no new uploads)")
        elif new_image_paths:
            # No image_paths in data, but new images uploaded - merge with existing
            final_image_paths = existing_image_paths + new_image_paths
            print(f"DEBUG Update: Merging {len(existing_image_paths)} existing + {len(new_image_paths)} new = {len(final_image_paths)} total images")
        else:
            # No changes to images, keep existing
            final_image_paths = existing_image_paths
            print(f"DEBUG Update: Keeping existing {len(final_image_paths)} images (no changes)")
        
        data['image_paths'] = final_image_paths
        
        # Prepare update data
        update_data = {}
        for key in ['name', 'description', 'category', 'price', 'quantity', 'unit', 'location', 'latitude', 'longitude', 'image_paths']:
            if key in data:
                update_data[key] = data[key]
        
        update_data['updated_at'] = 'SERVER_TIMESTAMP'
        
        try:
            success = MongoDBService.update_document('products', product_id, update_data)
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
        product_data = MongoDBService.get_document('products', product_id)
        if not product_data:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Soft delete by setting is_active to False
        MongoDBService.update_document('products', product_id, {
            'is_active': False,
            'updated_at': 'SERVER_TIMESTAMP'
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
def get_product_images(request, product_id):
    """Get all images for a product."""
    try:
        product = MongoDBService.get_document('products', product_id)
        if not product:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        image_paths = product.get('image_paths', [])
        return Response({
            'success': True,
            'image_paths': image_paths
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to retrieve images: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
