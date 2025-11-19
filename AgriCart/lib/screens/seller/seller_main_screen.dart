import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../widgets/app_drawer.dart';
import '../chat/chat_list_screen.dart';
import 'seller_dashboard_screen.dart';
import 'products_management_screen.dart';
import 'orders_management_screen.dart';
import 'analytics_screen.dart';

class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({super.key});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final sellerId = user?.userId ?? '';

        final List<Widget> screens = [
          SellerDashboardScreen(sellerId: sellerId),
          ProductsManagementScreen(sellerId: sellerId),
          OrdersManagementScreen(sellerId: sellerId),
          AnalyticsScreen(sellerId: sellerId),
          const ChatListScreen(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppBarTitle(_currentIndex)),
          ),
          drawer: AppDrawer(
            user: user,
            onLogout: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              AppRouter.navigateToLogin(context);
            },
            onProfileTap: () {
              Navigator.pop(context);
              // TODO: Navigate to profile screen
            },
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Seller Dashboard';
      case 1:
        return 'Manage Products';
      case 2:
        return 'Manage Orders';
      case 3:
        return 'Analytics';
      case 4:
        return 'Messages';
      default:
        return 'AgriCart';
    }
  }
}
