import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/message.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  static String get imageServiceUrl => dotenv.env['IMAGE_SERVICE_URL'] ?? 'http://localhost:8000/api/images';
  
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(User user, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': user.email,
        'password': password,
        'full_name': user.fullName,
        'phone_number': user.phoneNumber,
        'role': user.role,
        'address': user.address,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/'),
    );
    return _handleResponse(response);
  }

  // Product endpoints
  Future<List<Product>> getProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? search,
    String? sellerId,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (location != null) queryParams['location'] = location;
    if (search != null) queryParams['search'] = search;
    if (sellerId != null) queryParams['seller_id'] = sellerId;

    final uri = Uri.parse('$baseUrl/products/').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    final data = await _handleResponse(response);
    
    if (data['success'] == true) {
      return (data['products'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Product?> getProduct(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId/'),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return Product.fromJson(data['product']);
    }
    return null;
  }

  String getImageUrl(String imageId) {
    return '$imageServiceUrl/$imageId/';
  }

  // Order endpoints
  Future<Map<String, dynamic>> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/create/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'buyer_id': order.buyerId,
        'seller_id': order.sellerId,
        'items': order.items.map((item) => item.toJson()).toList(),
        'shipping_address': order.shippingAddress,
        'payment_method': order.paymentMethod,
        'total_amount': order.totalAmount,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<Order>> getOrders(String userId, String role) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/').replace(queryParameters: {
        'user_id': userId,
        'role': role,
      }),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return (data['orders'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Order?> getOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/'),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return Order.fromJson(data['order']);
    }
    return null;
  }

  // Chat endpoints
  Future<Map<String, dynamic>> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<Message>> getConversation(String user1Id, String user2Id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/').replace(queryParameters: {
        'user1_id': user1Id,
        'user2_id': user2Id,
      }),
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return (data['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();
    }
    return [];
  }

  // Payment endpoints
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );
    return _handleResponse(response);
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getSalesAnalytics(String sellerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/sales/').replace(queryParameters: {
        'seller_id': sellerId,
      }),
    );
    return _handleResponse(response);
  }
}

