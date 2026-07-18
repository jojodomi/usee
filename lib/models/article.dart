import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:usee/models/user.dart';

enum ArticleCategory {
  pants,
  skirt,
  heels,
  dress,
  shirt,
  jacket,
  shoes,
  bag,
  accessory;

  String get displayName {
    switch (this) {
      case ArticleCategory.pants:
        return 'Pantalon';
      case ArticleCategory.skirt:
        return 'Jupe';
      case ArticleCategory.heels:
        return 'Talons';
      case ArticleCategory.dress:
        return 'Robe';
      case ArticleCategory.shirt:
        return 'Chemise';
      case ArticleCategory.jacket:
        return 'Veste';
      case ArticleCategory.shoes:
        return 'Chaussures';
      case ArticleCategory.bag:
        return 'Sac';
      case ArticleCategory.accessory:
        return 'Accessoire';
    }
  }

  String get icon {
    switch (this) {
      case ArticleCategory.pants:
        return 'assets/icons/pants.png';
      case ArticleCategory.skirt:
        return 'assets/icons/skirt.png';
      case ArticleCategory.heels:
        return 'assets/icons/heels.png';
      case ArticleCategory.dress:
        return 'assets/icons/dress.png';
      case ArticleCategory.shirt:
        return 'assets/icons/shirt.png';
      case ArticleCategory.jacket:
        return 'assets/icons/jacket.png';
      case ArticleCategory.shoes:
        return 'assets/icons/shoes.png';
      case ArticleCategory.bag:
        return 'assets/icons/bag.png';
      case ArticleCategory.accessory:
        return 'assets/icons/accessory.png';
    }
  }
}

enum ArticleColor {
  black,
  white,
  red,
  blue,
  green,
  yellow,
  pink,
  purple,
  brown,
  gray,
  beige;

  String get displayName {
    switch (this) {
      case ArticleColor.black:
        return 'Noir';
      case ArticleColor.white:
        return 'Blanc';
      case ArticleColor.red:
        return 'Rouge';
      case ArticleColor.blue:
        return 'Bleu';
      case ArticleColor.green:
        return 'Vert';
      case ArticleColor.yellow:
        return 'Jaune';
      case ArticleColor.pink:
        return 'Rose';
      case ArticleColor.purple:
        return 'Violet';
      case ArticleColor.brown:
        return 'Marron';
      case ArticleColor.gray:
        return 'Gris';
      case ArticleColor.beige:
        return 'Beige';
    }
  }

  Color get colorValue {
    switch (this) {
      case ArticleColor.black:
        return Colors.black;
      case ArticleColor.white:
        return Colors.white;
      case ArticleColor.red:
        return Colors.red;
      case ArticleColor.blue:
        return Colors.blue;
      case ArticleColor.green:
        return Colors.green;
      case ArticleColor.yellow:
        return Colors.yellow;
      case ArticleColor.pink:
        return Colors.pink;
      case ArticleColor.purple:
        return Colors.purple;
      case ArticleColor.brown:
        return Colors.brown;
      case ArticleColor.gray:
        return Colors.grey;
      case ArticleColor.beige:
        return Color(0xFFF5F5DC);
    }
  }
}

enum ArticleCondition {
  brandNew,      // Au lieu de "new"
  likeNew,
  veryGood,
  good,
  acceptable;

  String get displayName {
    switch (this) {
      case ArticleCondition.brandNew:
        return 'Neuf';
      case ArticleCondition.likeNew:
        return 'Comme neuf';
      case ArticleCondition.veryGood:
        return 'Très bon état';
      case ArticleCondition.good:
        return 'Bon état';
      case ArticleCondition.acceptable:
        return 'État correct';
    }
  }

  int get percentage {
    switch (this) {
      case ArticleCondition.brandNew:
        return 100;
      case ArticleCondition.likeNew:
        return 90;
      case ArticleCondition.veryGood:
        return 75;
      case ArticleCondition.good:
        return 60;
      case ArticleCondition.acceptable:
        return 40;
    }
  }
  
  Color get color {
    switch (this) {
      case ArticleCondition.brandNew:
        return Colors.green;
      case ArticleCondition.likeNew:
        return Colors.blue;
      case ArticleCondition.veryGood:
        return Colors.teal;
      case ArticleCondition.good:
        return Colors.orange;
      case ArticleCondition.acceptable:
        return Colors.red;
    }
  }
  
  IconData get icon {
    switch (this) {
      case ArticleCondition.brandNew:
        return Icons.emergency;
      case ArticleCondition.likeNew:
        return Icons.star;
      case ArticleCondition.veryGood:
        return Icons.thumb_up;
      case ArticleCondition.good:
        return Icons.check_circle;
      case ArticleCondition.acceptable:
        return Icons.warning;
    }
  }
}

class Article {
  final String id;
  final String title;
  final String description;
  final double price;
  final ArticleCategory category;
  final String? brand;
  final String size;
  final ArticleColor color;
  final ArticleCondition condition;
  final List<String> images;
  final String sellerId;
  final AppUser? seller;
  final DateTime createdAt;
  final bool isActive;
  final int views;
  final bool isPromoted;
  final double? originalPrice;
  final bool isNegotiable;
  final String? location;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.brand,
    required this.size,
    required this.color,
    required this.condition,
    required this.images,
    required this.sellerId,
    this.seller,
    required this.createdAt,
    required this.isActive,
    required this.views,
    required this.isPromoted,
    this.originalPrice,
    this.isNegotiable = true,
    this.location,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      price: json['price'].toDouble(),
      category: _parseCategory(json['category']),
      brand: json['brand'],
      size: json['size'],
      color: _parseColor(json['color']),
      condition: _parseCondition(json['condition']),
      images: List<String>.from(json['images'] ?? []),
      sellerId: json['seller_id'],
      seller: json['seller'] != null ? AppUser.fromJson(json['seller']) : null,
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      views: json['views'] ?? 0,
      isPromoted: json['is_promoted'] ?? false,
      originalPrice: json['original_price']?.toDouble(),
      isNegotiable: json['is_negotiable'] ?? true,
      location: json['location'],
    );
  }

  static ArticleCategory _parseCategory(String category) {
    return ArticleCategory.values.firstWhere(
      (e) => e.toString() == 'ArticleCategory.$category',
      orElse: () => ArticleCategory.pants,
    );
  }

  static ArticleColor _parseColor(String color) {
    return ArticleColor.values.firstWhere(
      (e) => e.toString() == 'ArticleColor.$color',
      orElse: () => ArticleColor.black,
    );
  }

  static ArticleCondition _parseCondition(String condition) {
    return ArticleCondition.values.firstWhere(
      (e) => e.toString() == 'ArticleCondition.$condition',
      orElse: () => ArticleCondition.good,
    );
  }

  Map<String, dynamic> toJson() {
  final map = <String, dynamic>{
    // ❌ Retiré : 'id' → auto-généré par Supabase (UUID)
    // ❌ Retiré : 'created_at' → auto-généré par Supabase
    'title': title,
    'description': description,
    'price': price,
    'category': category.toString().split('.').last,
    'size': size,
    'color': color.toString().split('.').last,
    'condition': condition.toString().split('.').last,
    'images': images,
    'seller_id': sellerId,
    'is_active': isActive,
    'views': views,
    'is_promoted': isPromoted,
    'is_negotiable': isNegotiable,
    // Champs optionnels : n'envoyer que si non null
    if (brand != null && brand!.isNotEmpty) 'brand': brand,
    if (originalPrice != null) 'original_price': originalPrice,
    if (location != null && location!.isNotEmpty) 'location': location,
  };
  return map;
}

  bool get hasDiscount {
    return originalPrice != null && originalPrice! > price;
  }

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  String get formattedPrice {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  String get formattedOriginalPrice {
    return originalPrice != null ? '${originalPrice!.toStringAsFixed(0)} FCFA' : '';
  }
}