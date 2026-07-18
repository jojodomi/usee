import 'package:usee/models/user.dart';

class Like {
  final String id;
  final String articleId;
  final String userId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Comment {
  final String id;
  final String articleId;
  final String userId;
  final AppUser? user;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.articleId,
    required this.userId,
    this.user,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isEdited {
    return updatedAt != null && updatedAt != createdAt;
  }
}

class Report {
  final String id;
  final String articleId;
  final String userId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;
  final ReportStatus status;

  Report({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.reason,
    this.description,
    required this.createdAt,
    required this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      reason: ReportReason.values.firstWhere(
        (e) => e.toString() == json['reason'],
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
    );
  }
}

enum ReportReason {
  inappropriate,
  fake,
  spam,
  wrongCategory,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Contenu inapproprié';
      case ReportReason.fake:
        return 'Article faux ou trompeur';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.wrongCategory:
        return 'Mauvaise catégorie';
      case ReportReason.other:
        return 'Autre';
    }
  }
}

enum ReportStatus {
  pending,
  reviewed,
  rejected,
  resolved;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'En attente';
      case ReportStatus.reviewed:
        return 'Examiné';
      case ReportStatus.rejected:
        return 'Rejeté';
      case ReportStatus.resolved:
        return 'Résolu';
    }
  }
}