import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'fresh_produce':
        return '🌿';
      case 'livestock_poultry':
        return '🐔';
      case 'seeds_fertilizers':
        return '🌱';
      case 'farm_tools':
        return '🔧';
      case 'processed_goods':
        return '🥫';
      default:
        return '🌾';
    }
  }

  String _getCategoryName(String category) {
    return category.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        product.imagePaths.isNotEmpty ? product.imagePaths.first : null;

    // If imageUrl is relative, prepend base URL
    final fullImageUrl = imageUrl != null && !imageUrl.startsWith('http')
        ? '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl'
        : imageUrl;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio:
                    1.3, // Increased to reduce image height and give more space for content
                child: fullImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: fullImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.veryLightGreen,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.veryLightGreen,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: AppTheme.textGray,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.veryLightGreen,
                        child: Icon(
                          Icons.eco_outlined,
                          size: 50,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
              ),
            ),
            // Product Info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category badge
                  Row(
                    children: [
                      Text(
                        _getCategoryIcon(product.category),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _getCategoryName(product.category),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Product name
                  Text(
                    product.name,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Reduced further
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Price
                  Text(
                    '₱${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15, // Reduced further
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Location and quantity - more compact
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.location,
                          style: AppTheme.bodySmall.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 11,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${product.quantity} ${product.unit}',
                          style: AppTheme.bodySmall.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
