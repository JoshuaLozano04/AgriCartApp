import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class SellerEvent extends Equatable {
  const SellerEvent();

  @override
  List<Object?> get props => [];
}

class LoadSellerProductsEvent extends SellerEvent {
  final String sellerId;

  const LoadSellerProductsEvent({required this.sellerId});

  @override
  List<Object?> get props => [sellerId];
}

class CreateProductEvent extends SellerEvent {
  final Product product;
  final List<String> imagePaths;

  const CreateProductEvent({
    required this.product,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [product, imagePaths];
}

class UpdateProductEvent extends SellerEvent {
  final String productId;
  final Map<String, dynamic> updates;
  final List<String>? imagePaths;

  const UpdateProductEvent({
    required this.productId,
    required this.updates,
    this.imagePaths,
  });

  @override
  List<Object?> get props => [productId, updates, imagePaths];
}

class DeleteProductEvent extends SellerEvent {
  final String productId;

  const DeleteProductEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class LoadSalesAnalyticsEvent extends SellerEvent {
  // sellerId no longer needed - comes from token
  const LoadSalesAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

