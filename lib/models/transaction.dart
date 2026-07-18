import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:usee/models/article.dart';
import 'package:usee/models/user.dart';

enum PaymentMethod {
  orangeMoney,
  moovMoney,
  telecelMoney;

  String get displayName {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.telecelMoney:
        return 'Telecel Money';
    }
  }

  String get code {
    switch (this) {
      case PaymentMethod.orangeMoney:
        return 'OM';
      case PaymentMethod.moovMoney:
        return 'MM';
      case PaymentMethod.telecelMoney:
        return 'TM';
    }
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Complété';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.refunded:
        return 'Remboursé';
      case TransactionStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.refunded:
        return Colors.blue;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}

class Transaction {
  final String id;
  final String articleId;
  final Article? article;
  final String buyerId;
  final AppUser? buyer;
  final String sellerId;
  final AppUser? seller;
  final double amount;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? paymentReference;
  final String? paydunyaToken;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? deliveryAddress;
  final String? trackingNumber;

  Transaction({
    required this.id,
    required this.articleId,
    this.article,
    required this.buyerId,
    this.buyer,
    required this.sellerId,
    this.seller,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.paymentReference,
    this.paydunyaToken,
    required this.createdAt,
    this.completedAt,
    this.deliveryAddress,
    this.trackingNumber,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      articleId: json['article_id'],
      article: json['article'] != null ? Article.fromJson(json['article']) : null,
      buyerId: json['buyer_id'],
      buyer: json['buyer'] != null ? AppUser.fromJson(json['buyer']) : null,
      sellerId: json['seller_id'],
      seller: json['seller'] != null ? AppUser.fromJson(json['seller']) : null,
      amount: json['amount'].toDouble(),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      status: _parseTransactionStatus(json['status']),
      paymentReference: json['payment_reference'],
      paydunyaToken: json['paydunya_token'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      deliveryAddress: json['delivery_address'],
      trackingNumber: json['tracking_number'],
    );
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'orangeMoney':
        return PaymentMethod.orangeMoney;
      case 'moovMoney':
        return PaymentMethod.moovMoney;
      case 'telecelMoney':
        return PaymentMethod.telecelMoney;
      default:
        return PaymentMethod.orangeMoney;
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'refunded':
        return TransactionStatus.refunded;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'amount': amount,
      'payment_method': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'payment_reference': paymentReference,
      'paydunya_token': paydunyaToken,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'delivery_address': deliveryAddress,
      'tracking_number': trackingNumber,
    };
  }

  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;
}