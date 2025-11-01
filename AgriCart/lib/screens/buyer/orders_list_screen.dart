import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../services/api_service.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatelessWidget {
  final String userId;

  const OrdersListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(apiService: ApiService())
        ..add(LoadOrdersEvent(userId: userId, role: 'buyer')),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: Colors.green,
        ),
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OrdersBloc>().add(
                              LoadOrdersEvent(userId: userId, role: 'buyer'),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return const Center(
                  child: Text('No orders yet'),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OrdersBloc>().add(
                        LoadOrdersEvent(userId: userId, role: 'buyer'),
                      );
                },
                child: ListView.builder(
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('Order #${order.orderId.substring(0, 8)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${order.status.toUpperCase()}'),
                            Text(
                              'Items: ${order.items.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                orderId: order.orderId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

