enum UserType {
  client,
  simpleSeller,
  proSeller,
  boutique;

  String get displayName {
    switch (this) {
      case UserType.client:
        return 'Client';
      case UserType.simpleSeller:
        return 'Vendeur Simple';
      case UserType.proSeller:
        return 'Vendeur Pro';
      case UserType.boutique:
        return 'Boutique';
    }
  }

  String get apiValue {
    return toString().split('.').last;
  }
}

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserType userType;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;
  final String? bio;
  final String? address;
  final double? rating;
  final int totalSales;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.userType,
    this.avatarUrl,
    required this.createdAt,
    required this.isActive,
    this.bio,
    this.address,
    this.rating,
    this.totalSales = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      userType: _parseUserType(json['user_type']),
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      bio: json['bio'],
      address: json['address'],
      rating: json['rating'] != null ? json['rating'].toDouble() : null,
      totalSales: json['total_sales'] ?? 0,
    );
  }

  static UserType _parseUserType(String type) {
    switch (type) {
      case 'simpleSeller':
        return UserType.simpleSeller;
      case 'proSeller':
        return UserType.proSeller;
      case 'boutique':
        return UserType.boutique;
      default:
        return UserType.client;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'user_type': userType.apiValue,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'bio': bio,
      'address': address,
      'rating': rating,
      'total_sales': totalSales,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserType? userType,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isActive,
    String? bio,
    String? address,
    double? rating,
    int? totalSales,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      totalSales: totalSales ?? this.totalSales,
    );
  }

  bool get canSell {
    return userType != UserType.client;
  }

  String get userTypeDisplay {
    return userType.displayName;
  }
}