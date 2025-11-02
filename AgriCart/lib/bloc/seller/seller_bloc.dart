import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/token_storage_service.dart';
import 'seller_event.dart';
import 'seller_state.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class SellerBloc extends Bloc<SellerEvent, SellerState> {
  final ApiService apiService;
  final TokenStorageService _tokenStorage = TokenStorageService();
  String get baseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenv not initialized - will use default below
    }
    
    // Use ApiService's platform-aware baseUrl
    return ApiService.baseUrl;
  }

  SellerBloc({required this.apiService}) : super(SellerInitial()) {
    on<LoadSellerProductsEvent>(_onLoadSellerProducts);
    on<CreateProductEvent>(_onCreateProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<LoadSalesAnalyticsEvent>(_onLoadSalesAnalytics);
  }

  Future<void> _onLoadSellerProducts(
    LoadSellerProductsEvent event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      final products = await apiService.getProducts(sellerId: event.sellerId);
      emit(SellerProductsLoaded(products: products));
    } catch (e) {
      emit(SellerError(message: 'Failed to load products: $e'));
    }
  }

  Future<void> _onCreateProduct(
    CreateProductEvent event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      // Create multipart request for product with images
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/create/'),
      );

      // Add Authorization header
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add product data
      request.fields['seller_id'] = event.product.sellerId;
      request.fields['name'] = event.product.name;
      request.fields['description'] = event.product.description;
      request.fields['category'] = event.product.category;
      request.fields['price'] = event.product.price.toString();
      request.fields['quantity'] = event.product.quantity.toString();
      request.fields['unit'] = event.product.unit;
      request.fields['location'] = event.product.location;
      if (event.product.latitude != null) {
        request.fields['latitude'] = event.product.latitude.toString();
      }
      if (event.product.longitude != null) {
        request.fields['longitude'] = event.product.longitude.toString();
      }

      // Add images
      print('DEBUG SellerBloc: ===== IMAGE UPLOAD DEBUG =====');
      print('DEBUG SellerBloc: Adding ${event.imagePaths.length} image(s) to request');
      print('DEBUG SellerBloc: Image paths: ${event.imagePaths}');
      
      int addedCount = 0;
      for (var imagePath in event.imagePaths) {
        try {
          print('DEBUG SellerBloc: Processing image: $imagePath');
          
          // Handle file:// URIs on Android/iOS
          String actualPath = imagePath;
          if (imagePath.startsWith('file://')) {
            actualPath = imagePath.replaceFirst('file://', '');
          }
          
          final file = File(actualPath);
          final exists = await file.exists();
          print('DEBUG SellerBloc: File exists: $exists');
          
          if (exists) {
            final fileSize = await file.length();
            print('DEBUG SellerBloc: Image found - path: $actualPath, size: $fileSize bytes');
            
            try {
              // Read file bytes directly (works better on mobile)
              final fileBytes = await file.readAsBytes();
              print('DEBUG SellerBloc: Read ${fileBytes.length} bytes from file');
              
              // Determine content type from file extension
              final fileName = actualPath.split('/').last.toLowerCase();
              MediaType contentType;
              if (fileName.endsWith('.png')) {
                contentType = MediaType('image', 'png');
              } else if (fileName.endsWith('.gif')) {
                contentType = MediaType('image', 'gif');
              } else if (fileName.endsWith('.webp')) {
                contentType = MediaType('image', 'webp');
              } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
                contentType = MediaType('image', 'jpeg');
              } else {
                contentType = MediaType('image', 'jpeg'); // Default
              }
              print('DEBUG SellerBloc: Detected content type: ${contentType.toString()} for file: $fileName');
              
              // Create multipart file from bytes (more reliable on mobile)
              // Reading bytes directly avoids file system permission issues on mobile
              final multipartFile = http.MultipartFile.fromBytes(
                'images', 
                fileBytes,
                filename: actualPath.split('/').last,
                contentType: contentType,
              );
              
              print('DEBUG SellerBloc: MultipartFile created - field: ${multipartFile.field}, filename: ${multipartFile.filename}, length: ${multipartFile.length}');
              
              request.files.add(multipartFile);
              addedCount++;
              print('DEBUG SellerBloc: ✓ Added image file to request');
            } catch (multipartError) {
              print('DEBUG SellerBloc: ✗ Error creating MultipartFile: $multipartError');
              print('DEBUG SellerBloc: Stack trace: ${StackTrace.current}');
            }
          } else {
            print('DEBUG SellerBloc: ✗ Image file NOT found: $actualPath');
            print('DEBUG SellerBloc: Original path was: $imagePath');
          }
        } catch (e, stackTrace) {
          print('DEBUG SellerBloc: ✗ Error processing image $imagePath: $e');
          print('DEBUG SellerBloc: Stack trace: $stackTrace');
        }
      }
      print('DEBUG SellerBloc: ===== REQUEST SUMMARY =====');
      print('DEBUG SellerBloc: Total ${addedCount} image file(s) added to request');
      print('DEBUG SellerBloc: Request URL: ${request.url}');
      print('DEBUG SellerBloc: Request method: ${request.method}');
      print('DEBUG SellerBloc: Request headers: ${request.headers}');
      print('DEBUG SellerBloc: Request fields: ${request.fields}');
      print('DEBUG SellerBloc: Request files count: ${request.files.length}');
      
      // Log details of each file
      for (int i = 0; i < request.files.length; i++) {
        final file = request.files[i];
        print('DEBUG SellerBloc: File $i: field=${file.field}, filename=${file.filename}, length=${file.length}');
      }

      final response = await request.send();
      print('DEBUG SellerBloc: Response status: ${response.statusCode}');
      print('DEBUG SellerBloc: Response headers: ${response.headers}');
      
      final responseBody = await response.stream.bytesToString();
      print('DEBUG SellerBloc: Response body: $responseBody');
      
      final data = json.decode(responseBody);

      if (response.statusCode == 201 && data['success'] == true) {
        emit(ProductCreated(productId: data['product_id']));
        // Reload products
        add(LoadSellerProductsEvent(sellerId: event.product.sellerId));
      } else {
        print('DEBUG SellerBloc: Request failed - Status: ${response.statusCode}, Message: ${data['message'] ?? 'Unknown error'}');
        emit(SellerError(message: data['message'] ?? 'Failed to create product'));
      }
    } catch (e) {
      emit(SellerError(message: 'Error creating product: $e'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/products/${event.productId}/update/'),
      );

      // Add Authorization header
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add update fields
      event.updates.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            // For lists (like image_paths), send as JSON string
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add new images if provided (using bytes-based upload like create)
      if (event.imagePaths != null && event.imagePaths!.isNotEmpty) {
        print('DEBUG SellerBloc Update: Adding ${event.imagePaths!.length} new image(s)');
        for (var imagePath in event.imagePaths!) {
          try {
            String actualPath = imagePath;
            if (imagePath.startsWith('file://')) {
              actualPath = imagePath.replaceFirst('file://', '');
            }
            
            final file = File(actualPath);
            if (await file.exists()) {
              final fileBytes = await file.readAsBytes();
              final fileName = actualPath.split('/').last.toLowerCase();
              MediaType contentType;
              if (fileName.endsWith('.png')) {
                contentType = MediaType('image', 'png');
              } else if (fileName.endsWith('.gif')) {
                contentType = MediaType('image', 'gif');
              } else if (fileName.endsWith('.webp')) {
                contentType = MediaType('image', 'webp');
              } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
                contentType = MediaType('image', 'jpeg');
              } else {
                contentType = MediaType('image', 'jpeg'); // Default
              }
              final multipartFile = http.MultipartFile.fromBytes(
                'images',
                fileBytes,
                filename: actualPath.split('/').last,
                contentType: contentType,
              );
              request.files.add(multipartFile);
              print('DEBUG SellerBloc Update: Added image ${actualPath.split('/').last} with content type: ${contentType.toString()}');
            }
          } catch (e) {
            print('DEBUG SellerBloc Update: Error adding image $imagePath: $e');
          }
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(ProductUpdated());
      } else {
        emit(SellerError(message: data['message'] ?? 'Failed to update product'));
      }
    } catch (e) {
      emit(SellerError(message: 'Error updating product: $e'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        emit(SellerError(message: 'Authentication required'));
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/${event.productId}/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;
      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(ProductDeleted());
        // Reload products after deletion
        // Note: We need sellerId to reload, but event doesn't have it
        // The UI should handle reloading after receiving ProductDeleted state
      } else {
        emit(SellerError(message: data['message'] ?? 'Failed to delete product'));
      }
    } catch (e) {
      emit(SellerError(message: 'Error deleting product: $e'));
    }
  }

  Future<void> _onLoadSalesAnalytics(
    LoadSalesAnalyticsEvent event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      final response = await apiService.getSalesAnalytics();
      if (response['success'] == true) {
        emit(SalesAnalyticsLoaded(analytics: response['analytics']));
      } else {
        emit(SellerError(message: response['message'] ?? 'Failed to load analytics'));
      }
    } catch (e) {
      emit(SellerError(message: 'Error loading analytics: $e'));
    }
  }
}

