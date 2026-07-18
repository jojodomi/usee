enum SubscriptionType {
  monthly,
  quarterly,
  semiannual,
  annual;

  String get displayName {
    switch (this) {
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.quarterly:
        return 'Trimestriel';
      case SubscriptionType.semiannual:
        return 'Semestriel';
      case SubscriptionType.annual:
        return 'Annuel';
    }
  }

  int get durationDays {
    switch (this) {
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.quarterly:
        return 90;
      case SubscriptionType.semiannual:
        return 180;
      case SubscriptionType.annual:
        return 365;
    }
  }

  double get price {
    switch (this) {
      case SubscriptionType.monthly:
        return 5000;
      case SubscriptionType.quarterly:
        return 13500;
      case SubscriptionType.semiannual:
        return 25000;
      case SubscriptionType.annual:
        return 45000;
    }
  }

  int get maxPublications {
    switch (this) {
      case SubscriptionType.monthly:
        return 10;
      case SubscriptionType.quarterly:
        return 35;
      case SubscriptionType.semiannual:
        return 80;
      case SubscriptionType.annual:
        return 200;
    }
  }

  bool get hasAds {
    switch (this) {
      case SubscriptionType.monthly:
        return false;
      case SubscriptionType.quarterly:
        return true;
      case SubscriptionType.semiannual:
        return true;
      case SubscriptionType.annual:
        return true;
    }
  }

  double get discountPercentage {
    switch (this) {
      case SubscriptionType.monthly:
        return 0;
      case SubscriptionType.quarterly:
        return 10;
      case SubscriptionType.semiannual:
        return 15;
      case SubscriptionType.annual:
        return 20;
    }
  }

  double get discountedPrice {
    return price * (1 - discountPercentage / 100);
  }
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final int maxPublications;
  final bool hasAds;
  final bool isActive;
  final int publicationsUsed;
  final DateTime? createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.maxPublications,
    required this.hasAds,
    required this.isActive,
    this.publicationsUsed = 0,
    this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      type: _parseSubscriptionType(json['type']),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      amount: json['amount'].toDouble(),
      maxPublications: json['max_publications'],
      hasAds: json['has_ads'] ?? false,
      isActive: json['is_active'] ?? true,
      publicationsUsed: json['publications_used'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  static SubscriptionType _parseSubscriptionType(String type) {
    switch (type) {
      case 'monthly':
        return SubscriptionType.monthly;
      case 'quarterly':
        return SubscriptionType.quarterly;
      case 'semiannual':
        return SubscriptionType.semiannual;
      case 'annual':
        return SubscriptionType.annual;
      default:
        return SubscriptionType.monthly;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'amount': amount,
      'max_publications': maxPublications,
      'has_ads': hasAds,
      'is_active': isActive,
      'publications_used': publicationsUsed,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  bool get canPublish {
    return isActive && !isExpired && publicationsUsed < maxPublications;
  }

  int get remainingPublications {
    return maxPublications - publicationsUsed;
  }

  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  double get progressPercentage {
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsedDuration = DateTime.now().difference(startDate).inDays;
    if (totalDuration == 0) return 0;
    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }
}