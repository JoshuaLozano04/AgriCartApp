class Review {
  final String reviewId;
  final String productId;
  final String sellerId;
  final String buyerId;
  final int rating; // 1-5
  final String? comment;
  final String? createdAt;

  Review({
    required this.reviewId,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? '',
      productId: json['product_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'product_id': productId,
      'seller_id': sellerId,
      'buyer_id': buyerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}

