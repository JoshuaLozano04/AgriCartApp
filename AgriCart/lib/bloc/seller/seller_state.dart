import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class SellerState extends Equatable {
  const SellerState();

  @override
  List<Object?> get props => [];
}

class SellerInitial extends SellerState {}

class SellerLoading extends SellerState {}

class SellerProductsLoaded extends SellerState {
  final List<Product> products;

  const SellerProductsLoaded({required this.products});

  @override
  List<Object?> get props => [products];
}

class ProductCreated extends SellerState {
  final String productId;

  const ProductCreated({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class ProductUpdated extends SellerState {}

class ProductDeleted extends SellerState {}

class SalesAnalyticsLoaded extends SellerState {
  final Map<String, dynamic> analytics;

  const SalesAnalyticsLoaded({required this.analytics});

  @override
  List<Object?> get props => [analytics];
}

class SellerError extends SellerState {
  final String message;

  const SellerError({required this.message});

  @override
  List<Object?> get props => [message];
}

