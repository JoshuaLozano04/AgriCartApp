import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/products/products_bloc.dart';
import '../../bloc/products/products_event.dart';
import '../../bloc/products/products_state.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../services/api_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(apiService: ApiService())
        ..add(LoadProductDetailsEvent(productId: productId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          backgroundColor: Colors.green,
        ),
        body: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProductsBloc>().add(
                              LoadProductDetailsEvent(productId: productId),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is ProductDetailsLoaded) {
              final product = state.product;
              final imageUrls = product.imageIds
                  .map((id) => ApiService().getImageUrl(id))
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (imageUrls.isNotEmpty)
                            SizedBox(
                              height: 300,
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: imageUrls[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.image),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              height: 300,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 100),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  product.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on),
                                    const SizedBox(width: 8),
                                    Text(product.location),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Quantity: ${product.quantity} ${product.unit}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: product.quantity > 0
                                ? () {
                                    final cartBloc =
                                        context.read<CartBloc>();
                                    cartBloc.add(AddToCartEvent(
                                      productId: product.productId,
                                      price: product.price,
                                      quantity: 1,
                                    ));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
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

