import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../../models/cart.dart';

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

  @override
  Widget build(BuildContext context) {
    final cartBloc = context.read<CartBloc>();
    Cart? cart;
    
    return BlocBuilder<CartBloc, CartState>(
      bloc: cartBloc,
      builder: (context, state) {
        cart = state is CartInitial
            ? state.cart
            : (state as CartUpdated).cart;
        
        return _buildContent(context, cart!);
      },
    );
  }
  
  Widget _buildContent(BuildContext context, Cart cart) {

      return BlocProvider(
        create: (context) => OrdersBloc(apiService: ApiService()),
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.green,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your shipping address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shipping address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...['cod', 'gcash', 'maya', 'bank_transfer'].map((method) {
                  return RadioListTile<String>(
                    title: Text(method.toUpperCase()),
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  );
                }),
                const SizedBox(height: 24),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${cart.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 24),
                  BlocConsumer<OrdersBloc, OrdersState>(
                  listener: (context, state) {
                    if (state is OrderCreated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order placed successfully!'),
                        ),
                      );
                      context.read<CartBloc>().add(const ClearCartEvent());
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else if (state is OrdersError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Get user ID from auth state
                          // For now, using placeholder
                          final buyerId = 'user-id-placeholder';
                          final sellerId = cart.items.first.productId; // Simplified
                          
                          final order = Order(
                            orderId: '',
                            buyerId: buyerId,
                            sellerId: sellerId,
                            items: cart.items.map((item) => OrderItem(
                              productId: item.productId,
                              quantity: item.quantity,
                              price: item.price,
                            )).toList(),
                            shippingAddress: _addressController.text.trim(),
                            paymentMethod: _selectedPaymentMethod,
                            totalAmount: cart.totalAmount,
                            status: 'pending',
                          );

                          context.read<OrdersBloc>().add(
                                CreateOrderEvent(order: order),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

