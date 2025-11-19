import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../services/api_service.dart';

class AnalyticsScreen extends StatelessWidget {
  final String sellerId;

  const AnalyticsScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerBloc(apiService: ApiService())
        ..add(const LoadSalesAnalyticsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
        ),
        body: BlocBuilder<SellerBloc, SellerState>(
          builder: (context, state) {
            if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SellerError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SellerBloc>().add(
                              const LoadSalesAnalyticsEvent(),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is SalesAnalyticsLoaded) {
              final analytics = state.analytics;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Revenue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₱${(analytics['total_revenue'] ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bar chart for sales by product (quantity sold)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sales by Product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ProductSalesBarChart(
                              products: (analytics['top_products'] as List?) ?? const [],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${analytics['total_orders'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if ((analytics['top_products'] as List?) != null &&
                                (analytics['top_products'] as List).isNotEmpty)
                              ...(analytics['top_products'] as List)
                                  .map((product) => ListTile(
                                        title: Text(
                                          (product['product_name'] ?? '').toString().isNotEmpty
                                              ? product['product_name']
                                              : 'Product #${product['product_id'].toString().substring(0, 8)}',
                                        ),
                                        trailing: Text(
                                          '${product['quantity_sold']} sold',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  .toList()
                            else
                              const Text('No top products yet'),
                          ],
                        ),
                      ),
                    ),
                  ],
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

class _ProductSalesBarChart extends StatelessWidget {
  final List products; // expects list of maps with product_name/product_id and quantity_sold

  const _ProductSalesBarChart({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Text('No sales data yet');
    }

    // Prepare data
    final items = products.map<Map<String, dynamic>>((p) {
      final name = (p['product_name'] ?? '').toString().isNotEmpty
          ? p['product_name']
          : 'Product #${p['product_id'].toString().substring(0, 8)}';
      final qty = (p['quantity_sold'] ?? 0) as num;
      return {'name': name, 'qty': qty};
    }).toList();

    final maxQty = (items.map((e) => e['qty'] as num).fold<num>(0, (a, b) => a > b ? a : b)).toDouble();

    const double chartHeight = 240; // extra space to avoid overflow from labels
    const double barWidth = 24;
    const double maxBarHeight = 150; // slightly smaller to accommodate labels

    return SizedBox(
      height: chartHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: items.map((e) {
            final qty = (e["qty"] as num).toDouble();
            final ratio = maxQty > 0 ? (qty / maxQty).clamp(0, 1) : 0.0;
            final barHeight = maxBarHeight * ratio;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${qty.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: Text(
                      e['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

