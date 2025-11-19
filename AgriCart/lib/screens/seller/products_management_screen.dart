import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../buyer/product_detail_screen.dart';

class ProductsManagementScreen extends StatelessWidget {
  final String sellerId;

  const ProductsManagementScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerBloc(apiService: ApiService())
        ..add(LoadSellerProductsEvent(sellerId: sellerId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Products'),
        ),
        backgroundColor: AppTheme.backgroundGray,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductScreen(sellerId: sellerId),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
        ),
        body: BlocConsumer<SellerBloc, SellerState>(
          listener: (context, state) {
            if (state is ProductCreated || state is ProductUpdated || state is ProductDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state is ProductCreated
                        ? 'Product created successfully'
                        : state is ProductUpdated
                            ? 'Product updated successfully'
                            : 'Product deleted successfully',
                  ),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
              // Reload products
              context.read<SellerBloc>().add(LoadSellerProductsEvent(sellerId: sellerId));
            } else if (state is SellerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SellerLoading) {
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
                        context.read<SellerBloc>().add(
                              LoadSellerProductsEvent(sellerId: sellerId),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is SellerProductsLoaded) {
              if (state.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 100,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No products yet',
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding your first product',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductScreen(sellerId: sellerId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<SellerBloc>().add(
                        LoadSellerProductsEvent(sellerId: sellerId),
                      );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryGreen,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Further reduced to give more vertical space
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return Stack(
                      children: [
                        ProductCard(
                          product: product,
                          onTap: () {
                            // Navigate to product detail screen (seller view - no cart functionality)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  productId: product.productId,
                                  isSellerView: true,
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showProductOptions(context, product),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showProductOptions(BuildContext context, product) {
    // Capture SellerBloc from parent context before showing bottom sheet
    final sellerBloc = context.read<SellerBloc>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: AppTheme.primaryGreen),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: product.productId,
                      isSellerView: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryGreen),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (editContext) => BlocProvider.value(
                      value: sellerBloc,
                      child: EditProductScreen(product: product),
                    ),
                  ),
                );
                // Note: Products will be reloaded automatically via BlocListener
                // when ProductUpdated state is emitted from the shared SellerBloc
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.errorRed),
              title: const Text('Delete Product'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDelete(context, product, sellerBloc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, product, SellerBloc sellerBloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              sellerBloc.add(
                    DeleteProductEvent(productId: product.productId),
                  );
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
