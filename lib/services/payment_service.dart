
// lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.paydunya.com/v1';
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _apiSecret = 'YOUR_API_SECRET';
  static const String _masterKey = 'YOUR_MASTER_KEY';

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String description,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required PaymentMethod method,
  }) async {
    final url = Uri.parse('$_baseUrl/invoice/create');

    final headers = {
      'Content-Type': 'application/json',
      'PAYDUNYA-API-KEY': _apiKey,
      'PAYDUNYA-API-SECRET': _apiSecret,
      'PAYDUNYA-MASTER-KEY': _masterKey,
    };

    final body = {
      'amount': amount,
      'description': description,
      'customer': {
        'name': customerName,
        'phone': customerPhone,
        'email': customerEmail,
      },
      'currency': 'XOF',
      'custom_data': {
        'payment_method': method.toString(),
      },
    };

    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'invoice_url': data['invoice_url'],
          'token': data['token'],
        };
      }
      return {
        'success': false,
        'error': 'Payment initiation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String token) async {
    final url = Uri.parse('$_baseUrl/invoice/confirm/$token');

    final headers = {
      'Content-Type': 'application/json',
      'PAYDUNYA-API-KEY': _apiKey,
      'PAYDUNYA-API-SECRET': _apiSecret,
      'PAYDUNYA-MASTER-KEY': _masterKey,
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'transaction_id': data['transaction_id'],
        };
      }
      return {
        'success': false,
        'error': 'Payment confirmation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}