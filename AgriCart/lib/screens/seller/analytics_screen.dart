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
        // AppBar removed - will be handled by parent SellerMainScreen
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
                                          'Product #${product['product_id'].toString().substring(0, 8)}',
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

