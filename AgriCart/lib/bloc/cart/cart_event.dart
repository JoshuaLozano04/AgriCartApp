import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final String productId;
  final double price;
  final int quantity;

  const AddToCartEvent({
    required this.productId,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, price, quantity];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class UpdateCartItemQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

