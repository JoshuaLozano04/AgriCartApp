import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/api_service.dart';
import 'seller_event.dart';
import 'seller_state.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerBloc extends Bloc<SellerEvent, SellerState> {
  final ApiService apiService;
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';

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
      for (var imagePath in event.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images', imagePath),
          );
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 201 && data['success'] == true) {
        emit(ProductCreated(productId: data['product_id']));
        // Reload products
        add(LoadSellerProductsEvent(sellerId: event.product.sellerId));
      } else {
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

      // Add update fields
      event.updates.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add new images if provided
      if (event.imagePaths != null) {
        for (var imagePath in event.imagePaths!) {
          final file = File(imagePath);
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath('images', imagePath),
            );
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
      // Delete endpoint would need to be called
      emit(ProductDeleted());
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
      final response = await apiService.getSalesAnalytics(event.sellerId);
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

