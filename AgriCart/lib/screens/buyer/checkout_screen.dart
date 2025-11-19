import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../../navigation/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _selectedPaymentMethod = 'cod';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'gcash':
        return 'GCash';

      default:
        return method.toUpperCase();
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cod':
        return Icons.money_outlined;
      case 'gcash':
        return Icons.account_balance_wallet_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final cart = cartState is CartInitial
            ? cartState.cart
            : (cartState as CartUpdated).cart;

        if (cart.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Checkout'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppTheme.textGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return BlocProvider(
          create: (context) => OrdersBloc(apiService: ApiService()),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Checkout'),
            ),
            body: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is! AuthAuthenticated) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: AppTheme.textGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please login to checkout',
                          style: AppTheme.heading3,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            AppRouter.navigateToLogin(context);
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  );
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Order summary card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Order Summary',
                                          style: AppTheme.heading3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...cart.items.map((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Item x${item.quantity}',
                                                style: AppTheme.bodyMedium,
                                              ),
                                            ),
                                            Text(
                                              '₱${item.total.toStringAsFixed(2)}',
                                              style:
                                                  AppTheme.bodyLarge.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: AppTheme.heading3,
                                        ),
                                        Text(
                                          '₱${cart.totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Shipping address
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Shipping Address',
                                          style: AppTheme.heading3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Enter your complete shipping address',
                                        prefixIcon: Icon(Icons.home_outlined),
                                      ),
                                      maxLines: 3,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter shipping address';
                                        }
                                        if (value.length < 10) {
                                          return 'Please enter a complete address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Payment method
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payment_outlined,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Payment Method',
                                          style: AppTheme.heading3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...['cod', 'gcash'].map((method) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                _selectedPaymentMethod == method
                                                    ? AppTheme.primaryGreen
                                                    : Colors.grey.shade300,
                                            width:
                                                _selectedPaymentMethod == method
                                                    ? 2
                                                    : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color:
                                              _selectedPaymentMethod == method
                                                  ? AppTheme.veryLightGreen
                                                  : AppTheme.white,
                                        ),
                                        child: RadioListTile<String>(
                                          title: Row(
                                            children: [
                                              Icon(
                                                _getPaymentMethodIcon(method),
                                                color: AppTheme.primaryGreen,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                _getPaymentMethodName(method),
                                                style: AppTheme.bodyLarge,
                                              ),
                                            ],
                                          ),
                                          value: method,
                                          groupValue: _selectedPaymentMethod,
                                          activeColor: AppTheme.primaryGreen,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedPaymentMethod = value!;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      // Bottom button
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: BlocConsumer<OrdersBloc, OrdersState>(
                            listener: (context, state) async {
                              if (state is OrderCreated) {
                                // Automatically create payment for the order
                                context.read<OrdersBloc>().add(
                                      CreatePaymentEvent(
                                        orderId: state.orderId,
                                        paymentMethod: _selectedPaymentMethod,
                                        amount: cart.totalAmount,
                                      ),
                                    );
                              } else if (state is PaymentCreated) {
                                context.read<CartBloc>().add(
                                      const ClearCartEvent(),
                                    );

                                if (_selectedPaymentMethod == 'cod') {
                                  // COD - just show success and go home
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppTheme.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Order placed successfully! Payment will be collected on delivery.',
                                              style: const TextStyle(
                                                color: AppTheme.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppTheme.successGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  Navigator.of(context).popUntil(
                                    (route) => route.isFirst,
                                  );
                                } else {
                                  // Online payment - open payment URL
                                  if (state.paymentUrl != null &&
                                      state.paymentUrl!.isNotEmpty) {
                                    try {
                                      final uri = Uri.parse(state.paymentUrl!);
                                      // Use externalApplication mode to open in browser
                                      final launched = await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      if (!launched) {
                                        throw Exception('Could not launch URL');
                                      }
                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: AppTheme.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Order placed! Complete payment on the website.',
                                                  style: const TextStyle(
                                                    color: AppTheme.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              AppTheme.successGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                      Navigator.of(context).popUntil(
                                        (route) => route.isFirst,
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to open payment page: $e'),
                                          backgroundColor: AppTheme.errorRed,
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Payment URL not available'),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                }
                              } else if (state is OrdersError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.message),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            },
                            builder: (context, state) {
                              final isLoading = state is OrdersLoading;
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            final order = Order(
                                              orderId: '',
                                              buyerId: '', // From token
                                              sellerId: '', // From products
                                              items: cart.items
                                                  .map((item) => OrderItem(
                                                        productId:
                                                            item.productId,
                                                        quantity: item.quantity,
                                                        price: item.price,
                                                      ))
                                                  .toList(),
                                              shippingAddress:
                                                  _addressController.text
                                                      .trim(),
                                              paymentMethod:
                                                  _selectedPaymentMethod,
                                              totalAmount: cart.totalAmount,
                                              status: 'pending',
                                            );

                                            context.read<OrdersBloc>().add(
                                                  CreateOrderEvent(
                                                      order: order),
                                                );
                                          }
                                        },
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    isLoading
                                        ? 'Placing Order...'
                                        : 'Place Order',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
