import 'package:flutter/material.dart';
import '../models/article.dart';

class FiltersDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  
  const FiltersDialog({
    super.key,
    required this.onApply,
  });

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  ArticleCategory? _selectedCategory;
  ArticleColor? _selectedColor;
  String? _selectedBrand;
  String? _selectedSize;
  RangeValues _priceRange = const RangeValues(0, 1000000);
  TextEditingController _minPriceController = TextEditingController();
  TextEditingController _maxPriceController = TextEditingController();

  final List<String> _popularBrands = [
    'Nike',
    'Adidas',
    'Zara',
    'H&M',
    'Gucci',
    'Louis Vuitton',
  ];

  final List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
  ];

  @override
  void initState() {
    super.initState();
    _minPriceController.text = '0';
    _maxPriceController.text = '1000000';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    
    if (_selectedCategory != null) {
      filters['category'] = _selectedCategory;
    }
    if (_selectedColor != null) {
      filters['color'] = _selectedColor;
    }
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      filters['brand'] = _selectedBrand;
    }
    if (_selectedSize != null && _selectedSize!.isNotEmpty) {
      filters['size'] = _selectedSize;
    }
    if (_priceRange.start > 0) {
      filters['minPrice'] = _priceRange.start;
    }
    if (_priceRange.end < 1000000) {
      filters['maxPrice'] = _priceRange.end;
    }
    
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedColor = null;
      _selectedBrand = null;
      _selectedSize = null;
      _priceRange = const RangeValues(0, 1000000);
      _minPriceController.text = '0';
      _maxPriceController.text = '1000000';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const Divider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  const Text(
                    'Catégorie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ArticleCategory.values.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Price range
                  const Text(
                    'Prix (FCFA)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Min',
                            border: OutlineInputBorder(),
                            prefixText: 'CFA ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final min = double.tryParse(value) ?? 0;
                            setState(() {
                              _priceRange = RangeValues(
                                min,
                                _priceRange.end,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Max',
                            border: OutlineInputBorder(),
                            prefixText: 'CFA ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final max = double.tryParse(value) ?? 1000000;
                            setState(() {
                              _priceRange = RangeValues(
                                _priceRange.start,
                                max,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 100,
                    labels: RangeLabels(
                      '${_priceRange.start.toStringAsFixed(0)} FCFA',
                      '${_priceRange.end.toStringAsFixed(0)} FCFA',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                        _minPriceController.text = values.start.toStringAsFixed(0);
                        _maxPriceController.text = values.end.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Color
                  const Text(
                    'Couleur',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ArticleColor.values.map((color) {
                      final isSelected = _selectedColor == color;
                      return FilterChip(
                        label: Text(color.displayName),
                        selected: isSelected,
                        avatar: CircleAvatar(
                          radius: 8,
                          backgroundColor: color.colorValue,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedColor = selected ? color : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Brand
                  const Text(
                    'Marque',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _popularBrands.map((brand) {
                      final isSelected = _selectedBrand == brand;
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBrand = selected ? brand : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Size
                  const Text(
                    'Taille',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return FilterChip(
                        label: Text(size),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSize = selected ? size : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}