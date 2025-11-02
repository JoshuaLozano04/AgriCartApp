class OrderItem {
  final String productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Order {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;
  final String shippingAddress;
  final String paymentMethod;
  final double totalAmount;
  final String status;
  final String? paymentStatus;
  final String? trackingNumber;
  final String? createdAt;
  final String? updatedAt;

  Order({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    this.trackingNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      items: (json['items'] ?? []).map<OrderItem>((item) => OrderItem.fromJson(item)).toList(),
      shippingAddress: json['shipping_address'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cod',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'],
      trackingNumber: json['tracking_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'status': status,
      'payment_status': paymentStatus,
      'tracking_number': trackingNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

