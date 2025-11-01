import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductsEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? search;
  final String? sellerId;

  const LoadProductsEvent({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.search,
    this.sellerId,
  });

  @override
  List<Object?> get props => [category, minPrice, maxPrice, location, search, sellerId];
}

class LoadProductDetailsEvent extends ProductsEvent {
  final String productId;

  const LoadProductDetailsEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class RefreshProductsEvent extends ProductsEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? search;

  const RefreshProductsEvent({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.search,
  });

  @override
  List<Object?> get props => [category, minPrice, maxPrice, location, search];
}

