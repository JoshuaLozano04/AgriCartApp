import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/message.dart';
import 'token_storage_service.dart';

class ApiService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  static String get baseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        debugPrint('API Service: Using API_BASE_URL from .env: $envUrl');
        return envUrl;
      } else {
        debugPrint('API Service: API_BASE_URL not found in .env or is empty');
      }
    } catch (e) {
      // dotenv not initialized - will use default below
      debugPrint('API Service: dotenv not initialized, error: $e');
    }

    // Default URL based on platform
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      try {
        if (Platform.isAndroid) {
          // For Android emulator: 10.0.2.2 maps to host machine's localhost
          // For physical device: replace with your computer's IP address on the same network
          // Example: 'http://192.168.1.100:8000/api' (use your actual IP)
          return 'http://10.0.2.2:8000/api';
        } else if (Platform.isIOS) {
          // For iOS simulator: use localhost
          // For physical iOS device: use your computer's IP address
          return 'http://localhost:8000/api';
        }
      } catch (e) {
        // Platform class not available (e.g., on web) - use localhost
      }
      return 'http://localhost:8000/api';
    }
  }

  static String get imageServiceUrl {
    try {
      final envUrl = dotenv.env['IMAGE_SERVICE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenv not initialized - will use default below
    }

    // Default to baseUrl + /images
    return '${baseUrl.replaceAll('/api', '')}/api/images';
  }

  /// Get headers with authentication token if available
  Future<Map<String, String>> _getAuthHeaders(
      {Map<String, String>? additionalHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      // Try to parse error response
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Request failed: ${response.statusCode} - ${errorBody['message'] ?? response.body}');
      } catch (e) {
        throw Exception(
            'Request failed: ${response.statusCode} - ${response.body}');
      }
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
    print('DEBUG API: Login request to $baseUrl/auth/login/');
    print('DEBUG API: Email: $email');
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('DEBUG API: Login request timed out');
          throw TimeoutException(
              'Connection to server timed out. Please check:\n'
              '1. Django server is running\n'
              '2. Correct IP address in .env (API_BASE_URL)\n'
              '3. Device and computer are on the same network\n'
              '4. Firewall is not blocking port 8000');
        },
      );
      print('DEBUG API: Login response status: ${response.statusCode}');
      print('DEBUG API: Login response body: ${response.body}');
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw Exception('Cannot connect to server at $baseUrl\n'
          'Error: ${e.message}\n'
          'Please verify:\n'
          '- Server is running: python manage.py runserver 0.0.0.0:8000\n'
          '- Correct IP in .env file\n'
          '- Same Wi-Fi network');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Wrong email or password');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _getAuthHeaders();
    final token = await _tokenStorage.getToken();
    print(
        'DEBUG: Token retrieved: ${token != null ? "Token exists (${token.length} chars)" : "No token"}');
    print(
        'DEBUG: Authorization header: ${headers['Authorization'] ?? "Not set"}');
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile/'),
      headers: headers,
    );
    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');
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

    final uri =
        Uri.parse('$baseUrl/products/').replace(queryParameters: queryParams);
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
    // If imageId is a full S3 URL, return as is
    if (imageId.startsWith('http')) return imageId;
    // Otherwise, build S3 URL from env
    return '$imageServiceUrl/$imageId';
  }

  // Order endpoints
  Future<Map<String, dynamic>> createOrder(Order order) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/create/'),
      headers: headers,
      body: json.encode({
        // buyer_id comes from token, not from order
        'seller_id': order.sellerId,
        'items': order.items.map((item) => item.toJson()).toList(),
        'shipping_address': order.shippingAddress,
        'payment_method': order.paymentMethod,
        'total_amount': order.totalAmount,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<Order>> getOrders() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/'),
      headers: headers,
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
    debugPrint('DEBUG ApiService.getOrder: Fetching order $orderId');
    try {
      final headers = await _getAuthHeaders();
      debugPrint(
          'DEBUG ApiService.getOrder: Headers prepared, token: ${headers.containsKey('Authorization') ? "present" : "missing"}');
      debugPrint(
          'DEBUG ApiService.getOrder: Request URL: $baseUrl/orders/$orderId/');

      final response = await http
          .get(
        Uri.parse('$baseUrl/orders/$orderId/'),
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('DEBUG ApiService.getOrder: Request timed out');
          throw TimeoutException(
              'Connection to server timed out. Please check your network connection.');
        },
      );

      debugPrint(
          'DEBUG ApiService.getOrder: Response status: ${response.statusCode}');
      debugPrint(
          'DEBUG ApiService.getOrder: Response body length: ${response.body.length}');

      final data = await _handleResponse(response);
      debugPrint(
          'DEBUG ApiService.getOrder: Parsed response, success: ${data['success']}');

      if (data['success'] == true) {
        final order = Order.fromJson(data['order']);
        debugPrint(
            'DEBUG ApiService.getOrder: Order parsed successfully, orderId: ${order.orderId}');
        return order;
      }
      debugPrint('DEBUG ApiService.getOrder: Response success is false');
      return null;
    } on SocketException catch (e) {
      debugPrint('DEBUG ApiService.getOrder: SocketException: ${e.message}');
      throw Exception('Cannot connect to server\nError: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('DEBUG ApiService.getOrder: TimeoutException: ${e.message}');
      throw Exception(e.message);
    } catch (e, stackTrace) {
      debugPrint('DEBUG ApiService.getOrder: Exception: $e');
      debugPrint('DEBUG ApiService.getOrder: Stack trace: $stackTrace');
      throw Exception('Failed to load order: $e');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
  }) async {
    final headers = await _getAuthHeaders();
    final body = <String, dynamic>{'status': status};
    if (trackingNumber != null && trackingNumber.isNotEmpty) {
      body['tracking_number'] = trackingNumber;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/update-status/'),
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // Chat endpoints
  Future<Map<String, dynamic>> sendMessage(
    String receiverId,
    String message,
  ) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send/'),
      headers: headers,
      body: json.encode({
        // sender_id comes from token
        'receiver_id': receiverId,
        'message': message,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<Message>> getConversation(String user2Id) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/').replace(queryParameters: {
        // user1_id comes from token
        'user2_id': user2Id,
      }),
      headers: headers,
    );
    final data = await _handleResponse(response);
    if (data['success'] == true) {
      return (data['messages'] as List)
          .map((json) => Message.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Get all conversations for current user
  Future<Map<String, dynamic>> getUserConversations() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Get messages for a specific conversation
  Future<Map<String, dynamic>> getConversationMessages(
      String conversationId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$conversationId/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Create or get conversation with another user
  Future<Map<String, dynamic>> createOrGetConversation(
      String otherUserId) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/conversation/create/'),
      headers: headers,
      body: json.encode({
        'user2_id': otherUserId,
      }),
    );
    return _handleResponse(response);
  }

  /// Mark all messages in a conversation as read
  Future<Map<String, dynamic>> markConversationRead(
      String conversationId) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/messages/conversation/$conversationId/mark-read/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Payment endpoints
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create/'),
      headers: headers,
      body: json.encode({
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/confirm/'),
      headers: headers,
      body: json.encode({
        'payment_intent_id': paymentIntentId,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getPayment(String orderId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/payments/order/$orderId/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getSalesAnalytics() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/sales/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Notifications
  Future<Map<String, dynamic>> registerFcmToken(String token) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/register-token/'),
      headers: headers,
      body: json.encode({'token': token}),
    );
    return _handleResponse(response);
  }
}
