// lib/screens/payment/payment_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/paydunya_service.dart';
import 'payment_success_screen.dart';

class PaymentWebView extends StatefulWidget {
  final String invoiceUrl;
  final String invoiceToken;
  final double amount;
  final VoidCallback onSuccess;

  const PaymentWebView({
    super.key,
    required this.invoiceUrl,
    required this.invoiceToken,
    required this.amount,
    required this.onSuccess,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isChecking = false;
  bool _paymentHandled = false; // ✅ Empêche les doubles traitements
  final PayDunyaService _payDunyaService = PayDunyaService();

  @override
  void initState() {
    super.initState();
    _validateAndLoadUrl(); // ✅ Valider l'URL avant de charger
  }

  // ✅ NOUVEAU : Valider l'URL avant de charger
  void _validateAndLoadUrl() {
    final url = widget.invoiceUrl;
    debugPrint('🔗 Invoice URL: $url');
    debugPrint('🎫 Invoice Token: ${widget.invoiceToken}');

    // Vérifier que l'URL est valide
    if (url.isEmpty || !url.startsWith('http')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL de paiement invalide'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      });
      return;
    }

    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            debugPrint('🌐 Page started: $url');
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            debugPrint('✅ Page finished: $url');
            _handleUrlChange(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description}');
            // ✅ Ignorer les erreurs non critiques (sous-ressources)
            if (error.isForMainFrame == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onUrlChange: (UrlChange change) {
            debugPrint('🔗 URL change: ${change.url}');
            if (change.url != null) {
              _handleUrlChange(change.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🧭 Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..loadRequest(Uri.parse(widget.invoiceUrl));
  }

  // ✅ NOUVEAU : Centraliser la logique de détection d'URL
  void _handleUrlChange(String url) {
    if (_paymentHandled) return;

    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('success') ||
        lowerUrl.contains('return') ||
        lowerUrl.contains('payment-success') ||
        lowerUrl.contains('completed')) {
      debugPrint('🎯 URL de succès détectée: $url');
      _checkPaymentStatus();
    } else if (lowerUrl.contains('cancel') ||
        lowerUrl.contains('failure') ||
        lowerUrl.contains('failed')) {
      debugPrint('❌ URL d\'échec détectée: $url');
      _handlePaymentCancelled();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || _paymentHandled) return;

    setState(() => _isChecking = true);

    try {
      debugPrint('🔍 Vérification du statut: ${widget.invoiceToken}');
      final result =
          await _payDunyaService.checkTransactionStatus(widget.invoiceToken);
      debugPrint('📊 Résultat: $result');

      if (!mounted) return;

      final status = result['status']?.toString().toLowerCase() ?? '';

      if (result['success'] == true && status == 'completed') {
        _paymentHandled = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              amount: widget.amount,
              transactionId:
                  result['transaction_id'] ?? widget.invoiceToken,
              onDone: widget.onSuccess,
            ),
          ),
        );
      } else if (status == 'cancelled') {
        _paymentHandled = true;
        _handlePaymentCancelled();
      } else if (status == 'failed') {
        _paymentHandled = true;
        _handlePaymentFailed();
      } else {
        // ✅ Limiter les tentatives pour éviter la boucle infinie
        debugPrint('⏳ Statut en attente: $status');
        await Future.delayed(const Duration(seconds: 5));
        if (mounted && !_paymentHandled) {
          setState(() => _isChecking = false);
          _checkPaymentStatus();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _handlePaymentCancelled() {
    if (!mounted || _paymentHandled) return;
    _paymentHandled = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Paiement annulé'), backgroundColor: Colors.orange),
    );
    Navigator.pop(context);
  }

  void _handlePaymentFailed() {
    if (!mounted || _paymentHandled) return;
    _paymentHandled = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Paiement échoué. Veuillez réessayer.'),
          backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handlePaymentCancelled,
        ),
        actions: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
