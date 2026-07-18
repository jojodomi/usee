// lib/services/paydunya_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayDunyaService {
  // ✅ Les clés sont lues depuis .env
  static String get _masterKey => dotenv.env['PAYDUNYA_MASTER_KEY'] ?? '';
  static String get _privateKey => dotenv.env['PAYDUNYA_PRIVATE_KEY'] ?? '';
  static String get _token => dotenv.env['PAYDUNYA_TOKEN'] ?? '';
  static bool get _isTestMode => dotenv.env['PAYDUNYA_MODE'] == 'test';
  
  // URLs du store (lues depuis .env)
  static String get _storeName => dotenv.env['STORE_NAME'] ?? 'Used';
  static String get _storeUrl => dotenv.env['STORE_URL'] ?? 'https://used.com';
  static String get _storeLogo => dotenv.env['STORE_LOGO'] ?? 'https://used.com/logo.png';
  static String get _cancelUrl => dotenv.env['CANCEL_URL'] ?? 'https://used.com/cancel';
  static String get _returnUrl => dotenv.env['RETURN_URL'] ?? 'https://used.com/success';
  static String get _callbackUrl => dotenv.env['CALLBACK_URL'] ?? 'https://used.com/callback';

  static const String _baseUrl = 'https://app.paydunya.com/api/v1';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'PAYDUNYA-MASTER-KEY': _masterKey,
        'PAYDUNYA-PRIVATE-KEY': _privateKey,
        'PAYDUNYA-TOKEN': _token,
      };

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String description,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String paymentMethod,
  }) async {
    // 🔐 Vérifier que les clés sont configurées
    if (_masterKey.isEmpty || _privateKey.isEmpty || _token.isEmpty) {
      return {
        'success': false,
        'error': 'PayDunya: Clés API manquantes dans .env',
      };
    }

    final url = Uri.parse('$_baseUrl/checkout-invoice/create');

    final body = {
      'invoice': {
        'total_amount': amount.toInt(),
        'description': description,
        'customer': {
          'name': customerName,
          'phone': customerPhone,
          'email': customerEmail,
        },
      },
      'store': {
        'name': _storeName,
        'website_url': _storeUrl,
        'logo_url': _storeLogo,
      },
      'actions': {
        'cancel_url': _cancelUrl,
        'return_url': _returnUrl,
        'callback_url': _callbackUrl,
      },
      'custom_data': {
        'payment_method': paymentMethod,
        'platform': 'flutter',
      },
    };

    try {
      if (kDebugMode) {
        print('📤 URL: $url');
        print('📤 Headers: ${_headers.keys}');
        print('📤 Body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('📥 Status HTTP: ${response.statusCode}');
        print('📥 Body: ${response.body}');
      }

      if (response.body.trimLeft().startsWith('<!')) {
        return {
          'success': false,
          'error': 'Authentification refusée. Vérifiez vos clés API PayDunya dans .env',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseCode = data['response_code']?.toString();

        if (responseCode != '00') {
          return {
            'success': false,
            'error': data['response_text'] ?? 'Erreur inconnue (code: $responseCode)',
          };
        }

        final invoiceUrl = data['response_text']?.toString() ?? '';
        final token = data['token']?.toString() ?? '';

        if (invoiceUrl.isEmpty || !invoiceUrl.startsWith('http')) {
          return {
            'success': false,
            'error': 'URL invalide reçue: $invoiceUrl',
          };
        }

        if (kDebugMode) {
          print('✅ Invoice URL: $invoiceUrl');
          print('✅ Token: $token');
        }

        return {
          'success': true,
          'invoice_url': invoiceUrl,
          'invoice_token': token,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus(String invoiceToken) async {
    final url = Uri.parse('$_baseUrl/checkout-invoice/confirm/$invoiceToken');

    try {
      if (kDebugMode) print('🔍 Vérification: $url');

      final response = await http.get(url, headers: _headers);

      if (kDebugMode) {
        print('📊 Status HTTP: ${response.statusCode}');
        print('📊 Body: ${response.body}');
      }

      if (response.body.trimLeft().startsWith('<!')) {
        return {'success': false, 'status': 'pending', 'error': 'Auth refusée'};
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toLowerCase() ?? 'pending';

        return {
          'success': true,
          'status': status,
          'transaction_id': data['invoice']?['token'] ?? invoiceToken,
          'amount': data['invoice']?['total_amount'],
          'customer': data['customer'],
        };
      } else {
        return {
          'success': false,
          'status': 'pending',
          'error': 'Erreur HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur vérification: $e');
      return {
        'success': false,
        'status': 'pending',
        'error': e.toString(),
      };
    }
  }
}