import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
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
      case 'all':
        return '🌾';
      default:
        return '🌾';
    }
  }

  String _getCategoryName(String category) {
    if (category == 'all') {
      return 'All Categories';
    }
    return category.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.veryLightGreen,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCategoryIcon(category),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              _getCategoryName(category),
              style: TextStyle(
                color: isSelected ? AppTheme.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

