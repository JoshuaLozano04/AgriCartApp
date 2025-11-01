import 'product.dart';

class CartItem {
  final String productId;
  final Product? product; // Product details if loaded
  final int quantity;
  final double price;

  CartItem({
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;

  CartItem copyWith({
    String? productId,
    Product? product,
    int? quantity,
    double? price,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }
}

