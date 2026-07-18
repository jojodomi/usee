// lib/screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/article.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/paydunya_service.dart';
import '../../widgets/loading_widget.dart';
import 'payment_webview.dart';

class PaymentScreen extends StatefulWidget {
  final Article? article;
  final double? amount;
  final String? description;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final VoidCallback? onSuccess;
  
  const PaymentScreen({
    super.key,
    this.article,
    this.amount,
    this.description,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.onSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  late double _amount;
  late String _description;
  late String _customerName;
  late String _customerPhone;
  late String _customerEmail;
  
  final PayDunyaService _payDunyaService = PayDunyaService();

  @override
  void initState() {
    super.initState();
    _initializePaymentDetails();
  }

  void _initializePaymentDetails() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (widget.article != null) {
      _amount = widget.article!.price;
      _description = 'Achat: ${widget.article!.title}';
      _customerName = widget.customerName ?? authProvider.user?.fullName ?? '';
      _customerPhone = widget.customerPhone ?? authProvider.user?.phone ?? '';
      _customerEmail = widget.customerEmail ?? authProvider.user?.email ?? '';
    } else {
      _amount = widget.amount ?? 0;
      _description = widget.description ?? '';
      _customerName = widget.customerName ?? authProvider.user?.fullName ?? '';
      _customerPhone = widget.customerPhone ?? authProvider.user?.phone ?? '';
      _customerEmail = widget.customerEmail ?? authProvider.user?.email ?? '';
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final result = await _payDunyaService.initiatePayment(
        amount: _amount,
        description: _description,
        customerName: _customerName,
        customerPhone: _customerPhone,
        customerEmail: _customerEmail,
        paymentMethod: _selectedMethod!,
      );
      
      if (result['success'] && mounted) {
        // Ouvrir le WebView pour le paiement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(
              invoiceUrl: result['invoice_url'],
              invoiceToken: result['invoice_token'],
              amount: _amount,
              onSuccess: widget.onSuccess ?? () {},
            ),
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Erreur d\'initiation du paiement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isProcessing
          ? const LoadingWidget(message: 'Préparation du paiement...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Montant à payer',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_amount.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Détails
                  const Text(
                    'Détails',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_description),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Méthodes de paiement
                  const Text(
                    'Moyens de paiement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildPaymentMethod(
                    'orange',
                    'Orange Money',
                    Icons.phone_android,
                    Colors.orange,
                  ),
                  _buildPaymentMethod(
                    'moov',
                    'Moov Money',
                    Icons.phone_iphone,
                    Colors.blue,
                  ),
                  _buildPaymentMethod(
                    'tmoney',
                    'Togo Money',
                    Icons.signal_cellular_alt,
                    Colors.red,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton payer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Payer maintenant',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sécurité
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Paiement sécurisé par PayDunya',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethod(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (val) {
                setState(() {
                  _selectedMethod = val;
                });
              },
              activeColor: color,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}