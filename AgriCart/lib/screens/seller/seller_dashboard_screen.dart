import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'products_management_screen.dart';
import 'analytics_screen.dart';
import 'orders_management_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  final String sellerId;

  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerBloc(apiService: ApiService())
        ..add(const LoadSalesAnalyticsEvent()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: BlocBuilder<SellerBloc, SellerState>(
          builder: (context, state) {
            if (state is SalesAnalyticsLoaded) {
              final analytics = state.analytics;
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<SellerBloc>().add(const LoadSalesAnalyticsEvent());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.store_outlined,
                                    color: AppTheme.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Seller Dashboard',
                                        style: AppTheme.heading2.copyWith(
                                          color: AppTheme.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage your farm products',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Revenue',
                              '₱${((analytics['total_revenue'] ?? 0) as num).toStringAsFixed(2)}',
                              Icons.attach_money_rounded,
                              AppTheme.primaryGreen,
                              AppTheme.veryLightGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Orders',
                              '${analytics['total_orders'] ?? 0}',
                              Icons.shopping_bag_outlined,
                              AppTheme.infoBlue,
                              AppTheme.infoBlue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Top Products',
                              '${(analytics['top_products'] as List?)?.length ?? 0}',
                              Icons.star_outline,
                              AppTheme.warningOrange,
                              AppTheme.warningOrange.withOpacity(0.1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Categories',
                              '${(analytics['category_performance'] as Map?)?.length ?? 0}',
                              Icons.category_outlined,
                              AppTheme.successGreen,
                              AppTheme.successGreen.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quick actions
                      Text(
                        'Quick Actions',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        context,
                        'Manage Products',
                        'Add, edit, or remove your products',
                        Icons.inventory_2_outlined,
                        () {
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
                      const SizedBox(height: 12),
                      _buildActionCard(
                        context,
                        'Manage Orders',
                        'View and update order status',
                        Icons.receipt_long_outlined,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrdersManagementScreen(
                                sellerId: sellerId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        context,
                        'View Analytics',
                        'See detailed sales insights',
                        Icons.analytics_outlined,
                        () {
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            } else if (state is SellerLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              );
            } else if (state is SellerError) {
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
                        context.read<SellerBloc>().add(const LoadSalesAnalyticsEvent());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.veryLightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textGray,
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
        ),
      ),
    );
  }
}
