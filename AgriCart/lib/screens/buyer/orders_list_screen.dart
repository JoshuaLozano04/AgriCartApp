import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatelessWidget {
  final String userId;

  const OrdersListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppTheme.textGray,
              ),
              const SizedBox(height: 16),
              Text(
                'Please login to view your orders',
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          OrdersBloc(apiService: ApiService())..add(const LoadOrdersEvent()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              );
            } else if (state is OrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.textGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrdersBloc>().add(const LoadOrdersEvent());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 100,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No orders yet',
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your orders will appear here',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OrdersBloc>().add(const LoadOrdersEvent());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryGreen,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return _buildOrderCard(context, order);
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

  Widget _buildOrderCard(BuildContext context, Order order) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status.toLowerCase()) {
      case 'pending':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.pending_outlined;
        break;
      case 'confirmed':
        statusColor = AppTheme.infoBlue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'processing':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'shipped':
        statusColor = AppTheme.primaryGreenDark;
        statusIcon = Icons.directions_car_outlined;
        break;
      case 'delivered':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppTheme.textGray;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatStatus(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGray,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Order details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPaymentMethodName(order.paymentMethod),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
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
}
