import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/buyer_main_screen.dart';
import '../screens/seller/seller_main_screen.dart';
import '../screens/buyer/order_detail_screen.dart';
import '../bloc/orders/orders_bloc.dart';
import '../bloc/orders/orders_event.dart';
import '../services/api_service.dart';

class AppRouter {
  static const String login = '/';
  static const String register = '/register';
  static const String buyerHome = '/buyer';
  static const String sellerHome = '/seller';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Intercept payment-related deep links that might come through routing system
    final routeName = settings.name ?? '';
    
    // Check if this is a payment deep link (might come as /success or /payment/success)
    if (routeName.contains('success') || routeName.contains('failed')) {
      // Try to extract order_id from route name or arguments
      String? orderId;
      
      // Check if order_id is in route name (e.g., /success?order_id=xxx)
      if (routeName.contains('order_id=')) {
        final uri = Uri.parse(routeName);
        orderId = uri.queryParameters['order_id'];
      }
      
      // Check if passed as arguments
      if (orderId == null && settings.arguments is Map) {
        final args = settings.arguments as Map<String, dynamic>?;
        orderId = args?['order_id'] as String?;
      }
      
      // If we have an order_id, navigate to order detail screen
      if (orderId != null && orderId.isNotEmpty) {
        final validOrderId = orderId; // Store in non-null variable
        return MaterialPageRoute(
          builder: (context) {
            // Create OrdersBloc and load order details
            final ordersBloc = OrdersBloc(apiService: ApiService());
            ordersBloc.add(LoadOrderDetailsEvent(orderId: validOrderId));
            return BlocProvider.value(
              value: ordersBloc,
              child: OrderDetailScreen(orderId: validOrderId),
            );
          },
          settings: settings,
        );
      }
    }
    
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case buyerHome:
        return MaterialPageRoute(
          builder: (_) => const BuyerMainScreen(),
          settings: settings,
        );
      case sellerHome:
        return MaterialPageRoute(
          builder: (_) => const SellerMainScreen(),
          settings: settings,
        );
      default:
        // Only show error for routes that don't look like deep links
        if (routeName.isNotEmpty && 
            !routeName.contains('success') && 
            !routeName.contains('failed') && 
            !routeName.contains('payment') &&
            !routeName.contains('order_id')) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
            settings: settings,
          );
        }
        // For potential deep links, return a loading screen (will be handled by AppLinks)
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          settings: settings,
        );
    }
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed(register);
  }

  static void navigateToBuyerHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(buyerHome);
  }

  static void navigateToSellerHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(sellerHome);
  }
}

