import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/product.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cart = state is CartInitial
              ? state.cart
              : (state as CartUpdated).cart;

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: AppTheme.textGray,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your cart is empty',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding products to your cart',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return FutureBuilder<Product?>(
                      future: ApiService().getProduct(item.productId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration,
                            child: const Row(
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                ),
                                SizedBox(width: 16),
                                Text('Loading...'),
                              ],
                            ),
                          );
                        }

                        final product = snapshot.data;
                        if (product == null) {
                          return const SizedBox();
                        }

                        final imageUrl = product.imagePaths.isNotEmpty
                            ? product.imagePaths.first
                            : null;
                        
                        final fullImageUrl = imageUrl != null &&
                                !imageUrl.startsWith('http')
                            ? '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl'
                            : imageUrl;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: AppTheme.veryLightGreen,
                                        child: fullImageUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: fullImageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.primaryGreen,
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(
                                                  Icons.image_not_supported,
                                                  color: AppTheme.textGray,
                                                ),
                                              )
                                            : Icon(
                                                Icons.eco_outlined,
                                                size: 40,
                                                color: AppTheme.primaryGreen,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Product info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: AppTheme.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${item.price.toStringAsFixed(2)} per ${product.unit}',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textGray,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Quantity controls
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.remove,
                                                        size: 18,
                                                        color:
                                                            AppTheme.primaryGreen,
                                                      ),
                                                      onPressed: item.quantity > 1
                                                          ? () {
                                                              context
                                                                  .read<
                                                                      CartBloc>()
                                                                  .add(
                                                                    UpdateCartItemQuantityEvent(
                                                                      productId:
                                                                          item
                                                                              .productId,
                                                                      quantity:
                                                                          item
                                                                                  .quantity -
                                                                              1,
                                                                    ),
                                                                  );
                                                            }
                                                          : null,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 40,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        '${item.quantity}',
                                                        style: AppTheme
                                                            .bodyLarge
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.add,
                                                        size: 18,
                                                        color:
                                                            AppTheme.primaryGreen,
                                                      ),
                                                      onPressed: item.quantity <
                                                              product.quantity
                                                          ? () {
                                                              context
                                                                  .read<
                                                                      CartBloc>()
                                                                  .add(
                                                                    UpdateCartItemQuantityEvent(
                                                                      productId:
                                                                          item
                                                                              .productId,
                                                                      quantity:
                                                                          item
                                                                                  .quantity +
                                                                              1,
                                                                    ),
                                                                  );
                                                            }
                                                          : null,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              // Item total
                                              Text(
                                                '₱${item.total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.errorRed,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Remove Item'),
                                            content: Text(
                                              'Remove ${product.name} from cart?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  context
                                                      .read<CartBloc>()
                                                      .add(
                                                        RemoveFromCartEvent(
                                                          productId:
                                                              item.productId,
                                                        ),
                                                      );
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        'Item removed from cart',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.successGreen,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Remove',
                                                  style: TextStyle(
                                                    color: AppTheme.errorRed,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Bottom summary
              Container(
                padding: const EdgeInsets.all(20),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: AppTheme.heading3,
                          ),
                          Text(
                            '₱${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: cart.items.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CheckoutScreen(),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
