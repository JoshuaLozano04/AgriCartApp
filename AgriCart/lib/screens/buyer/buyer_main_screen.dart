import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../widgets/app_drawer.dart';
import '../chat/chat_list_screen.dart';
import 'products_list_screen.dart';
import 'cart_screen.dart';
import 'orders_list_screen.dart';

class BuyerMainScreen extends StatefulWidget {
  const BuyerMainScreen({super.key});

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final userId = user?.userId ?? '';

        final List<Widget> screens = [
          const ProductsListScreen(),
          const CartScreen(),
          OrdersListScreen(userId: userId),
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
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
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
        return 'AgriCart';
      case 1:
        return 'Shopping Cart';
      case 2:
        return 'My Orders';
      case 3:
        return 'Messages';
      default:
        return 'AgriCart';
    }
  }
}
