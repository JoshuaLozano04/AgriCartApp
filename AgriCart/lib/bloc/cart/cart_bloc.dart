import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final currentCart = state is CartInitial
        ? (state as CartInitial).cart
        : (state as CartUpdated).cart;

    final existingItemIndex = currentCart.items.indexWhere(
      (item) => item.productId == event.productId,
    );

    List<CartItem> updatedItems;
    if (existingItemIndex >= 0) {
      updatedItems = List.from(currentCart.items);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex]
          .copyWith(quantity: updatedItems[existingItemIndex].quantity + event.quantity);
    } else {
      updatedItems = [
        ...currentCart.items,
        CartItem(
          productId: event.productId,
          quantity: event.quantity,
          price: event.price,
        ),
      ];
    }

    emit(CartUpdated(cart: Cart(items: updatedItems)));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final currentCart = state is CartInitial
        ? (state as CartInitial).cart
        : (state as CartUpdated).cart;

    final updatedItems = currentCart.items
        .where((item) => item.productId != event.productId)
        .toList();

    emit(CartUpdated(cart: Cart(items: updatedItems)));
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) {
    final currentCart = state is CartInitial
        ? (state as CartInitial).cart
        : (state as CartUpdated).cart;

    if (event.quantity <= 0) {
      add(RemoveFromCartEvent(productId: event.productId));
      return;
    }

    final updatedItems = currentCart.items.map((item) {
      if (item.productId == event.productId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    emit(CartUpdated(cart: Cart(items: updatedItems)));
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(CartUpdated(cart: Cart(items: [])));
  }
}

