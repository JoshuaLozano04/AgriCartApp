import 'package:equatable/equatable.dart';
import '../../models/cart.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  final Cart cart;

  CartInitial({Cart? cart}) : cart = cart ?? Cart(items: []);

  @override
  List<Object?> get props => [cart];
}

class CartUpdated extends CartState {
  final Cart cart;

  const CartUpdated({required this.cart});

  @override
  List<Object?> get props => [cart];
}

