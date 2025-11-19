import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'seller_order_detail_screen.dart';
import '../../models/order.dart';

class OrdersManagementScreen extends StatelessWidget {
  final String sellerId;

  const OrdersManagementScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(apiService: ApiService())
        ..add(const LoadOrdersEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
        ),
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
              final sellerOrders = state.orders; // Filtered by backend
              
              if (sellerOrders.isEmpty) {
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
                        'Orders will appear here when customers purchase',
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
                  itemCount: sellerOrders.length,
                  itemBuilder: (context, index) {
                    final order = sellerOrders[index];
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
      child: ExpansionTile(
        key: ValueKey('${order.orderId}_${order.status}'),
        leading: Container(
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
        title: Text(
          'Order #${order.orderId.substring(0, 8).toUpperCase()}',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // Keep default expand chevron; remove external-link icon
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatStatus(order.status),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₱${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Items: ${order.items.length}',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerOrderDetailScreen(orderId: order.orderId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, Order order) {
    final nextStatus = _getNextStatus(order.status);
    if (nextStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Text('Change status from ${_formatStatus(order.status)} to ${_formatStatus(nextStatus)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<OrdersBloc>().add(
                    UpdateOrderStatusEvent(
                      orderId: order.orderId,
                      status: nextStatus,
                    ),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Order status updated'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: Text(
              'Update',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  String? _getNextStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'processing';
      case 'processing':
        return 'shipped';
      default:
        return null;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) =>
            word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

