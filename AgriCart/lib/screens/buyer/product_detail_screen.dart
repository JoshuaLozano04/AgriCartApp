import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/products/products_bloc.dart';
import '../../bloc/products/products_event.dart';
import '../../bloc/products/products_state.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/category_chip.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool isSellerView;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isSellerView = false,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(apiService: ApiService())
        ..add(LoadProductDetailsEvent(productId: widget.productId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
        ),
        body: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              );
            } else if (state is ProductsError) {
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
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProductsBloc>().add(
                              LoadProductDetailsEvent(
                                productId: widget.productId,
                              ),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is ProductDetailsLoaded) {
              final product = state.product;
              final imagePaths = product.imagePaths.isNotEmpty
                  ? product.imagePaths
                  : <String>[];

              // Convert relative paths to full URLs
              final imageUrls = imagePaths.map((path) {
                if (path.startsWith('http')) return path;
                return '${ApiService.baseUrl.replaceAll('/api', '')}$path';
              }).toList();

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image gallery
                          if (imageUrls.isNotEmpty)
                            Container(
                              height: 350,
                              color: AppTheme.veryLightGreen,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    itemCount: imageUrls.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      return CachedNetworkImage(
                                        imageUrl: imageUrls[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppTheme.veryLightGreen,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.primaryGreen,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: AppTheme.veryLightGreen,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 60,
                                            color: AppTheme.textGray,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (imageUrls.length > 1)
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          imageUrls.length,
                                          (index) => Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _currentImageIndex == index
                                                  ? AppTheme.primaryGreen
                                                  : AppTheme.white
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 350,
                              color: AppTheme.veryLightGreen,
                              child: Center(
                                child: Icon(
                                  Icons.eco_outlined,
                                  size: 100,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          
                          // Product info
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: AppTheme.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category chip
                                CategoryChip(
                                  category: product.category,
                                  isSelected: true,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 16),
                                // Product name
                                Text(
                                  product.name,
                                  style: AppTheme.heading2.copyWith(
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Price
                                Text(
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Description
                                Text(
                                  'Description',
                                  style: AppTheme.heading3,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description,
                                  style: AppTheme.bodyLarge.copyWith(
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                // Location
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: AppTheme.primaryGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Location',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.location,
                                            style: AppTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Stock info
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppTheme.primaryGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Available Stock',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.quantity} ${product.unit}',
                                            style: AppTheme.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: product.quantity > 0
                                                  ? AppTheme.primaryGreen
                                                  : AppTheme.errorRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Quantity selector (only for buyers)
                                if (!widget.isSellerView && product.quantity > 0) ...[
                                  Text(
                                    'Quantity',
                                    style: AppTheme.heading3,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.primaryGreen,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                color: AppTheme.primaryGreen,
                                              ),
                                              onPressed: _quantity > 1
                                                  ? () {
                                                      setState(() {
                                                        _quantity--;
                                                      });
                                                    }
                                                  : null,
                                            ),
                                            Container(
                                              width: 60,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              child: Text(
                                                '$_quantity',
                                                textAlign: TextAlign.center,
                                                style: AppTheme.heading3,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: AppTheme.primaryGreen,
                                              ),
                                              onPressed: _quantity <
                                                      product.quantity
                                                  ? () {
                                                      setState(() {
                                                        _quantity++;
                                                      });
                                                    }
                                                  : null,
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
                        ],
                      ),
                    ),
                  ),
                  // Bottom action bar (only for buyers)
                  if (!widget.isSellerView)
                    if (product.quantity > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                    Text(
                                      '₱${(product.price * _quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<CartBloc>().add(
                                          AddToCartEvent(
                                            productId: product.productId,
                                            price: product.price,
                                            quantity: _quantity,
                                          ),
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Added $_quantity ${product.unit} to cart',
                                              style: const TextStyle(
                                                color: AppTheme.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.successGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined),
                                  label: const Text('Add to Cart'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.errorRed,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
