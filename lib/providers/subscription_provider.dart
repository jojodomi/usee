import 'package:flutter/material.dart';
import '../models/subscription.dart';
//import '../models/user.dart';
import '../services/supabase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  Subscription? _currentSubscription;
  List<Subscription> _subscriptionHistory = [];
  bool _isLoading = false;
  String? _error;

  Subscription? get currentSubscription => _currentSubscription;
  List<Subscription> get subscriptionHistory => _subscriptionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription => 
      _currentSubscription != null && _currentSubscription!.canPublish;

  Future<void> loadCurrentSubscription(String userId) async {
    _setLoading(true);

    try {
      _currentSubscription = await _supabaseService.getCurrentSubscription(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSubscriptionHistory(String userId) async {
    _setLoading(true);

    try {
      _subscriptionHistory = await _supabaseService.getSubscriptionHistory(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> subscribe(
    String userId,
    SubscriptionType type,
    String paymentToken,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      // Verify payment first
      final paymentConfirmed = await _verifyPayment(paymentToken);
      
      if (!paymentConfirmed) {
        throw Exception('Paiement non confirmé');
      }

      // Create subscription
      await _supabaseService.subscribe(userId, type);
      
      // Reload subscription
      await loadCurrentSubscription(userId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _verifyPayment(String token) async {
    // Implement payment verification logic
    // This would call your payment service
    return true;
  }

  Future<bool> canPublish(String userId) async {
    if (_currentSubscription == null) {
      await loadCurrentSubscription(userId);
    }
    
    if (_currentSubscription == null) return false;
    
    return _currentSubscription!.canPublish;
  }

  Future<int> getRemainingPublications(String userId) async {
    if (_currentSubscription == null) {
      await loadCurrentSubscription(userId);
    }
    
    return _currentSubscription?.remainingPublications ?? 0;
  }

  Future<void> incrementPublicationsUsed(String userId) async {
    if (_currentSubscription != null) {
      await _supabaseService.incrementPublicationsUsed(_currentSubscription!.id);
      await loadCurrentSubscription(userId);
    }
  }

  List<SubscriptionType> getAvailablePlans() {
    return SubscriptionType.values;
  }

  SubscriptionType getRecommendedPlan() {
    final current = _currentSubscription;
    if (current == null) return SubscriptionType.monthly;
    
    // Suggest next plan based on usage
    if (current.publicationsUsed > current.maxPublications * 0.8) {
      // User is using most of their publications
      switch (current.type) {
        case SubscriptionType.monthly:
          return SubscriptionType.quarterly;
        case SubscriptionType.quarterly:
          return SubscriptionType.semiannual;
        case SubscriptionType.semiannual:
          return SubscriptionType.annual;
        case SubscriptionType.annual:
          return SubscriptionType.annual;
      }
    }
    
    return current.type;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}