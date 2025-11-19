import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/orders/orders_bloc.dart';
import '../../bloc/orders/orders_event.dart';
import '../../bloc/orders/orders_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(apiService: ApiService())
        ..add(LoadOrderDetailsEvent(orderId: orderId)),
      child: BlocListener<OrdersBloc, OrdersState>(
        listener: (context, state) {
          if (state is PaymentCreated && state.paymentUrl != null) {
            // Automatically open payment URL when created from order details
            launchUrl(
              Uri.parse(state.paymentUrl!),
              mode: LaunchMode.externalApplication,
            ).then((_) {
              // Refresh order details after a delay
              Future.delayed(const Duration(seconds: 2), () {
                context.read<OrdersBloc>().add(
                      LoadOrderDetailsEvent(orderId: orderId),
                    );
              });
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Order Details'),
          ),
          body: BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              print(
                  'DEBUG OrderDetailScreen: Current state: ${state.runtimeType}');
              if (state is OrdersLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                );
              } else if (state is OrdersError) {
                print(
                    'DEBUG OrderDetailScreen: Showing error: ${state.message}');
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.message,
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          print(
                              'DEBUG OrderDetailScreen: Retry button pressed');
                          context.read<OrdersBloc>().add(
                                LoadOrderDetailsEvent(orderId: orderId),
                              );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is OrderDetailsLoaded) {
                final order = state.order;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order status card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(order.status),
                                      color: _getStatusColor(order.status),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Order Status',
                                      style: AppTheme.heading3,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatStatus(order.status),
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (order.trackingNumber != null) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tracking Number',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.trackingNumber!,
                                          style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Shipping address
                      Container(
                        padding: const EdgeInsets.all(20),
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
                            const SizedBox(height: 12),
                            Text(
                              order.shippingAddress,
                              style: AppTheme.bodyLarge.copyWith(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Order items
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Items',
                                  style: AppTheme.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...order.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return FutureBuilder<Product?>(
                                future: ApiService().getProduct(item.productId),
                                builder: (context, snapshot) {
                                  final product = snapshot.data;
                                  return Container(
                                    margin: EdgeInsets.only(
                                      bottom: index < order.items.length - 1
                                          ? 12
                                          : 0,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundGray,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppTheme.veryLightGreen,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.eco_outlined,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product?.name ??
                                                    'Product ${item.productId.substring(0, 8)}',
                                                style:
                                                    AppTheme.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.quantity} x ₱${item.price.toStringAsFixed(2)}',
                                                style:
                                                    AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₱${item.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Payment info
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                  'Payment Information',
                                  style: AppTheme.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Payment Method',
                              _getPaymentMethodName(order.paymentMethod),
                            ),
                            if (order.paymentStatus != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Payment Status',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPaymentStatusColor(
                                            order.paymentStatus!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatPaymentStatus(
                                            order.paymentStatus!),
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (order.createdAt != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Order Date',
                                _formatDate(order.createdAt!),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: AppTheme.heading3,
                                ),
                                Text(
                                  '₱${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pay Now button for pending online payments
                      if (order.paymentStatus == 'pending' &&
                          order.paymentMethod != 'cod') ...[
                        BlocBuilder<OrdersBloc, OrdersState>(
                          builder: (context, state) {
                            final isLoading = state is OrdersLoading;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        // Get payment URL from backend
                                        try {
                                          final paymentResponse =
                                              await ApiService()
                                                  .getPayment(order.orderId);
                                          if (paymentResponse['success'] ==
                                              true) {
                                            final paymentUrl =
                                                paymentResponse['payment']
                                                    ?['payment_url'];
                                            if (paymentUrl != null &&
                                                paymentUrl.isNotEmpty) {
                                              final uri = Uri.parse(paymentUrl);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                                // Refresh order details after payment
                                                Future.delayed(
                                                    const Duration(seconds: 2),
                                                    () {
                                                  context
                                                      .read<OrdersBloc>()
                                                      .add(
                                                        LoadOrderDetailsEvent(
                                                            orderId:
                                                                order.orderId),
                                                      );
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Cannot open payment URL'),
                                                    backgroundColor:
                                                        AppTheme.errorRed,
                                                  ),
                                                );
                                              }
                                            } else {
                                              // Create new payment if URL doesn't exist
                                              context.read<OrdersBloc>().add(
                                                    CreatePaymentEvent(
                                                      orderId: order.orderId,
                                                      paymentMethod:
                                                          order.paymentMethod,
                                                      amount: order.totalAmount,
                                                    ),
                                                  );
                                            }
                                          } else {
                                            // Create new payment
                                            context.read<OrdersBloc>().add(
                                                  CreatePaymentEvent(
                                                    orderId: order.orderId,
                                                    paymentMethod:
                                                        order.paymentMethod,
                                                    amount: order.totalAmount,
                                                  ),
                                                );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor:
                                                  AppTheme.errorRed,
                                            ),
                                          );
                                        }
                                      },
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.white,
                                        ),
                                      )
                                    : const Icon(Icons.payment),
                                label: Text(
                                    isLoading ? 'Processing...' : 'Pay Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your payment using ${_getPaymentMethodName(order.paymentMethod)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'confirmed':
        return AppTheme.infoBlue;
      case 'processing':
        return AppTheme.primaryGreen;
      case 'shipped':
        return AppTheme.primaryGreenDark;
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.local_shipping_outlined;
      case 'shipped':
        return Icons.directions_car_outlined;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.warningOrange;
      case 'failed':
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending Payment';
      case 'failed':
        return 'Payment Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }
}
