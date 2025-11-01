import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/seller/seller_bloc.dart';
import '../../bloc/seller/seller_event.dart';
import '../../bloc/seller/seller_state.dart';
import '../../services/api_service.dart';
import 'add_product_screen.dart';

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
          title: const Text('My Products'),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(sellerId: sellerId),
                  ),
                );
              },
            ),
          ],
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
                              LoadSellerProductsEvent(sellerId: sellerId),
                            );
                      },
                      child: const Text('Retry'),
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
                      const Text('No products yet'),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductScreen(sellerId: sellerId),
                            ),
                          );
                        },
                        child: const Text('Add Product'),
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
                },
                child: ListView.builder(
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₱${product.price.toStringAsFixed(2)}'),
                            Text('Quantity: ${product.quantity} ${product.unit}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context.read<SellerBloc>().add(
                                  DeleteProductEvent(productId: product.productId),
                                );
                          },
                        ),
                      ),
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
}

