import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'bloc/bloc_observer.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/products/products_bloc.dart';
import 'bloc/cart/cart_bloc.dart';
import 'bloc/orders/orders_bloc.dart';
import 'bloc/orders/orders_event.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'screens/buyer/order_detail_screen.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  // On mobile: loads from assets/.env (bundled with app)
  // On desktop/web: can load from file system
  try {
    // Try loading from assets first (for mobile builds)
    // flutter_dotenv loads from root of assets, so use ".env" not "assets/.env"
    await dotenv.load();
    debugPrint('✓ Loaded .env file from assets');
    debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? 'NOT SET'}');
  } catch (assetsError) {
    // If loading from assets fails, try file system (for desktop/web development)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✓ Loaded .env file from file system');
      debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? 'NOT SET'}');
    } catch (fileError) {
      // .env file not found or inaccessible
      debugPrint('⚠ Warning: Could not load .env file from assets or file system');
      debugPrint('⚠ Assets error: $assetsError');
      debugPrint('⚠ File error: $fileError');
      debugPrint('⚠ Falling back to platform defaults');
      // Try to initialize with empty map to prevent NotInitializedError
      try {
        await dotenv.load(fileName: ".env", mergeWith: <String, String>{});
      } catch (_) {
        debugPrint('⚠ Note: Using default API URLs. Ensure .env is in assets folder.');
      }
    }
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  await NotificationService().initialize();
  
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Delay deep link initialization to ensure app is fully built
    Future.delayed(const Duration(milliseconds: 500), () {
      _initDeepLinks();
    });
  }

  void _initDeepLinks() {
    // Listen for deep links when app is already open
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );

    // Handle deep link when app is opened from a closed state
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleDeepLink(uri);
        });
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    debugPrint('Deep link path: ${uri.path}');
    debugPrint('Deep link pathSegments: ${uri.pathSegments}');
    debugPrint('Deep link queryParameters: ${uri.queryParameters}');
    
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator not available yet, retrying...');
      Future.delayed(const Duration(milliseconds: 500), () => _handleDeepLink(uri));
      return;
    }
    
    // Parse deep link URLs
    // Format: agricart://payment/success?order_id=xxx or
    //         https://agricart.app/payment/success?order_id=xxx
    // Handle different path formats:
    // - /payment/success or payment/success (from custom scheme)
    // - /payment/failed or payment/failed (from custom scheme)
    // - Full paths from universal links
    
    final fullPath = uri.path;
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;
    
    // Check for payment success/failed in various formats
    // Also check if path is just /success or /failed with order_id query param
    bool isPaymentSuccess = fullPath.contains('payment/success') || 
                           fullPath.contains('/payment/success') ||
                           fullPath == '/success' ||
                           fullPath == 'success' ||
                           (pathSegments.length >= 2 && 
                            pathSegments[0] == 'payment' && 
                            pathSegments[1] == 'success') ||
                           (fullPath.contains('success') && queryParams.containsKey('order_id'));
    
    bool isPaymentFailed = fullPath.contains('payment/failed') || 
                          fullPath.contains('/payment/failed') ||
                          fullPath == '/failed' ||
                          fullPath == 'failed' ||
                          (pathSegments.length >= 2 && 
                           pathSegments[0] == 'payment' && 
                           pathSegments[1] == 'failed') ||
                          (fullPath.contains('failed') && queryParams.containsKey('order_id'));
    
    if (isPaymentSuccess || isPaymentFailed) {
      // Try to get order_id from query parameters
      String? orderId = queryParams['order_id'];
      
      // If not in query params, try to extract from path (fallback)
      if ((orderId == null || orderId.isEmpty) && pathSegments.length >= 3) {
        // Format might be: agricart://payment/success/order_id
        orderId = pathSegments[pathSegments.length - 1];
      }
      
      debugPrint('Extracted orderId: $orderId');
      
      if (orderId != null && orderId.isNotEmpty) {
        // Store in non-null variable for type safety
        final validOrderId = orderId;
        // Navigate to order detail screen
        navigator.push(
          MaterialPageRoute(
            builder: (context) {
              // Get OrdersBloc from the widget tree
              final ordersBloc = OrdersBloc(apiService: ApiService());
              // Load order details when screen opens
              ordersBloc.add(LoadOrderDetailsEvent(orderId: validOrderId));
              return BlocProvider.value(
                value: ordersBloc,
                child: OrderDetailScreen(orderId: validOrderId),
              );
            },
          ),
        );
      } else {
        debugPrint('Warning: No order_id found in deep link');
      }
    } else if (uri.path.contains('/order/') && pathSegments.length >= 2) {
      // Handle agricart://order/{orderId}/pay
      final orderId = pathSegments[pathSegments.length - 2];
      if (orderId.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) {
              final ordersBloc = OrdersBloc(apiService: ApiService());
              ordersBloc.add(LoadOrderDetailsEvent(orderId: orderId));
              return BlocProvider.value(
                value: ordersBloc,
                child: OrderDetailScreen(orderId: orderId),
              );
            },
          ),
        );
      }
    } else if (queryParams.containsKey('order_id')) {
      // Catch-all: If there's an order_id in query params but path wasn't recognized,
      // treat it as a payment success (common case when path gets truncated)
      final orderId = queryParams['order_id'];
      if (orderId != null && orderId.isNotEmpty) {
        debugPrint('Catch-all: Treating as payment success with order_id: $orderId');
        final validOrderId = orderId;
        navigator.push(
          MaterialPageRoute(
            builder: (context) {
              final ordersBloc = OrdersBloc(apiService: ApiService());
              ordersBloc.add(LoadOrderDetailsEvent(orderId: validOrderId));
              return BlocProvider.value(
                value: ordersBloc,
                child: OrderDetailScreen(orderId: validOrderId),
              );
            },
          ),
        );
      }
    } else {
      debugPrint('Deep link not recognized: $uri');
      debugPrint('Path: $fullPath, Segments: $pathSegments, Query: $queryParams');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final authBloc = AuthBloc(apiService: ApiService());
            // Check for stored token on app start
            authBloc.add(const LoadStoredTokenEvent());
            return authBloc;
          },
        ),
        BlocProvider(
          create: (context) => ProductsBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => CartBloc(),
        ),
        BlocProvider(
          create: (context) => OrdersBloc(apiService: ApiService()),
        ),
      ],
      child: MaterialApp(
        title: 'AgriCart',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.login,
        navigatorKey: navigatorKey,
      ),
    );
  }
}

