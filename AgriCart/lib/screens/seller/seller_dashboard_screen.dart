import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../services/api_service.dart';
import 'products_management_screen.dart';
import 'analytics_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  final String sellerId;

  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerBloc(apiService: ApiService())
        ..add(LoadSalesAnalyticsEvent(sellerId: sellerId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: Colors.green,
        ),
        body: BlocBuilder<SellerBloc, SellerState>(
          builder: (context, state) {
            if (state is SalesAnalyticsLoaded) {
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
                              'Sales Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  'Total Revenue',
                                  '₱${(analytics['total_revenue'] ?? 0).toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                                _buildStatCard(
                                  'Total Orders',
                                  '${analytics['total_orders'] ?? 0}',
                                  Icons.shopping_bag,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        title: const Text('Manage Products'),
                        leading: const Icon(Icons.inventory),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsManagementScreen(
                                sellerId: sellerId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: const Text('View Analytics'),
                        leading: const Icon(Icons.analytics),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyticsScreen(
                                sellerId: sellerId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SellerError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

