// lib/services/paydunya_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PayDunyaService {
  static const String _masterKey = 'ujRk39QF-O255-J6hq-vyRy-Ty0XSaDBq24o';
  static const String _privateKey = 'test_private_6mqsU5d8hHRmHlLMBJGVaEvvL35';
  static const String _token = 'NRr6lKAx9jGjgqJFpWlP';
  static const bool _isTestMode = true;

  // ✅ CORRIGÉ : URLs correctes selon la doc officielle
  static const String _baseUrl = _isTestMode
      ? 'https://app.paydunya.com/sandbox-api/v1'
      : 'https://app.paydunya.com/api/v1';

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
    // ✅ CORRIGÉ : bon endpoint "checkout-invoice/create"
    final url = Uri.parse('$_baseUrl/checkout-invoice/create');

    // ✅ CORRIGÉ : structure exacte selon la doc PayDunya
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
        'name': 'Usee',
        'website_url': 'https://usee.com',
        'logo_url': 'https://usee.com/logo.png',
      },
      'actions': {
        'cancel_url': 'https://usee.com/cancel',
        'return_url': 'https://usee.com/success',
        'callback_url': 'https://usee.com/callback',
      },
      'custom_data': {
        'payment_method': paymentMethod,
        'platform': 'flutter',
      },
    };

    try {
      if (kDebugMode) {
        print('📤 URL: $url');
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

      // ✅ Si on reçoit du HTML → les clés API sont incorrectes
      if (response.body.trimLeft().startsWith('<!')) {
        return {
          'success': false,
          'error': 'Authentification refusée. Vérifiez vos clés API PayDunya.',
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

        // ✅ CORRIGÉ : response_text EST l'URL de checkout (doc confirmée)
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
          'invoice_url': invoiceUrl,  // URL directe du checkout
          'invoice_token': token,      // Token pour vérifier le statut
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
    // ✅ CORRIGÉ : bon endpoint de confirmation
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

        // ✅ Statuts PayDunya : completed | pending | cancelled | failed
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
