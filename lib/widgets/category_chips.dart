import 'package:flutter/material.dart';
import '../models/article.dart';

class CategoryChips extends StatelessWidget {
  final ArticleCategory? selectedCategory;
  final Function(ArticleCategory?) onCategorySelected;

  const CategoryChips({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All categories chip
          FilterChip(
            label: const Text('Tous'),
            selected: selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(null);
              }
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
          ),
          const SizedBox(width: 8),
          // Category chips
          ...ArticleCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
            );
          }),
        ],
      ),
    );
  }
}