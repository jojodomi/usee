import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Transaction> _transactions = [];
  bool _isProcessing = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String description,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required PaymentMethod method,
  }) async {
    _setProcessing(true);
    _error = null;

    try {
      final result = await _paymentService.initiatePayment(
        amount: amount,
        description: description,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        method: method,
      );

      return result;
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _setProcessing(false);
    }
  }

  Future<bool> confirmPayment(String token) async {
    _setProcessing(true);

    try {
      final result = await _paymentService.confirmPayment(token);
      return result['success'] == true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> createTransaction(Transaction transaction) async {
    _setProcessing(true);

    try {
      await _supabaseService.createTransaction(transaction);
      await loadUserTransactions(transaction.buyerId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> loadUserTransactions(String userId) async {
    _setProcessing(true);

    try {
      _transactions = await _supabaseService.getUserTransactions(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    _setProcessing(true);

    try {
      await _supabaseService.updateTransaction(transactionId, {
        'status': status.toString().split('.').last,
        'completed_at': status == TransactionStatus.completed 
            ? DateTime.now().toIso8601String()
            : null,
      });
      
      // Reload transactions
      final transaction = _transactions.firstWhere((t) => t.id == transactionId);
      await loadUserTransactions(transaction.buyerId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  List<Transaction> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  double getTotalSpent() {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int getCompletedTransactionsCount() {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .length;
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}