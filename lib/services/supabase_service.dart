// lib/services/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/article.dart';
import '../models/interaction.dart';
import '../models/transaction.dart';
import '../models/subscription.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // ==================== AUTH METHODS ====================
  Future<AuthResponse> signUp(String email, String password, String fullName, String phone) async {
    try {
      print('📝 Tentative d\'inscription: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'user_type': UserType.client.toString().split('.').last,
        },
      );
      
      print('✅ Inscription réussie: ${response.user?.id}');
      
      // Créer automatiquement l'utilisateur dans la table users
      if (response.user != null) {
        await _ensureUserExists(response.user!);
      }
      
      return response;
    } catch (e) {
      print('❌ Erreur inscription: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('🔐 Tentative de connexion: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('✅ Connexion réussie: ${response.user?.id}');
      
      if (response.user != null) {
        await _ensureUserExists(response.user!);
      }
      
      return response;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      rethrow;
    }
  }

  // Méthode pour s'assurer que l'utilisateur existe dans la table users
  Future<void> _ensureUserExists(User user) async {
    try {
      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingUser == null) {
        print('📝 Création de l\'utilisateur dans la table users');
        
        // Créer l'utilisateur dans la table users
        await _client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? '',
          'phone': user.userMetadata?['phone'] ?? '',
          'user_type': user.userMetadata?['user_type'] ?? 'client',
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
        });
        
        print('✅ Utilisateur créé dans la table users');
      } else {
        print('✅ Utilisateur déjà existant dans la table users');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la vérification/création utilisateur: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  // lib/services/supabase_service.dart
Future<AppUser?> getCurrentUser() async {
  try {
    final user = _client.auth.currentUser;
    if (user == null) {
      print('⚠️ Aucun utilisateur connecté');
      return null;
    }

    print('📱 Récupération des données pour: ${user.id}');
    print('📧 Email: ${user.email}');

    // Essayer de récupérer l'utilisateur
    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      print('⚠️ Utilisateur non trouvé dans la table users, création automatique...');
      
      // Créer l'utilisateur automatiquement
      final newUser = {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Utilisateur',
        'phone': user.userMetadata?['phone'] ?? '',
        'user_type': user.userMetadata?['user_type'] ?? 'client',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };
      
      await _client.from('users').insert(newUser);
      print('✅ Utilisateur créé dans la table users');
      
      // Récupérer l'utilisateur fraîchement créé
      final newResponse = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      return AppUser.fromJson(newResponse);
    }
    
    print('✅ Utilisateur chargé: ${response['full_name']}');
    return AppUser.fromJson(response);
  } catch (e) {
    print('❌ Erreur getCurrentUser: $e');
    return null;
  }
}

  // ==================== USER METHODS ====================
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('users')
          .update(updates)
          .eq('id', userId);
      print('✅ Utilisateur mis à jour: $userId');
    } catch (e) {
      debugPrint('Error in updateUser: $e');
      rethrow;
    }
  }

  Future<AppUser?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('Error in getUserById: $e');
      return null;
    }
  }

  // ==================== ARTICLE METHODS ====================
  Future<List<Article>> getArticles({
    ArticleCategory? category,
    double? minPrice,
    double? maxPrice,
    ArticleColor? color,
    String? brand,
    String? size,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('articles')
          .select('*, seller:users(*)');
      
      // Filtre actif
      query = query.eq('is_active', true);
      
      // Appliquer les filtres
      if (category != null) {
        query = query.eq('category', category.toString().split('.').last);
      }
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }
      if (color != null) {
        query = query.eq('color', color.toString().split('.').last);
      }
      if (brand != null && brand.isNotEmpty) {
        query = query.ilike('brand', '%$brand%');
      }
      if (size != null && size.isNotEmpty) {
        query = query.eq('size', size);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }
      
      // Trier et paginer
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map<Article>((json) => Article.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getArticles: $e');
      return [];
    }
  }

  Future<Article?> getArticleById(String id) async {
    try {
      final response = await _client
          .from('articles')
          .select('*, seller:users(*)')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return Article.fromJson(response);
    } catch (e) {
      debugPrint('Error in getArticleById: $e');
      return null;
    }
  }

  Future<List<Article>> getUserArticles(String userId) async {
    try {
      final response = await _client
          .from('articles')
          .select('*, seller:users(*)')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Article>((json) => Article.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getUserArticles: $e');
      return [];
    }
  }

  Future<List<Article>> getFavoriteArticles(String userId) async {
    try {
      final response = await _client
          .from('likes')
          .select('article:articles(*, seller:users(*))')
          .eq('user_id', userId);
      
      final List<Article> articles = [];
      for (var item in response) {
        articles.add(Article.fromJson(item['article']));
      }
      return articles;
    } catch (e) {
      debugPrint('Error in getFavoriteArticles: $e');
      return [];
    }
  }

  Future<void> createArticle(Article article) async {
    try {
      await _client.from('articles').insert(article.toJson());
    } catch (e) {
      debugPrint('Error in createArticle: $e');
      rethrow;
    }
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('articles').update(data).eq('id', id);
    } catch (e) {
      debugPrint('Error in updateArticle: $e');
      rethrow;
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _client.from('articles').update({'is_active': false}).eq('id', id);
    } catch (e) {
      debugPrint('Error in deleteArticle: $e');
      rethrow;
    }
  }

  Future<void> incrementViews(String articleId) async {
    try {
      await _client.rpc('increment_views', params: {'article_id': articleId});
    } catch (e) {
      debugPrint('Error in incrementViews: $e');
    }
  }

  // ==================== LIKE METHODS ====================
  Future<bool> isLiked(String articleId, String userId) async {
    try {
      final response = await _client
          .from('likes')
          .select()
          .eq('article_id', articleId)
          .eq('user_id', userId);
      
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error in isLiked: $e');
      return false;
    }
  }

  Future<void> likeArticle(String articleId, String userId) async {
    try {
      await _client.from('likes').insert({
        'article_id': articleId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error in likeArticle: $e');
      rethrow;
    }
  }

  Future<void> unlikeArticle(String articleId, String userId) async {
    try {
      await _client
          .from('likes')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error in unlikeArticle: $e');
      rethrow;
    }
  }

  Future<int> getLikesCount(String articleId) async {
    try {
      final response = await _client
          .from('likes')
          .select('count')
          .eq('article_id', articleId);
      
      return response.length;
    } catch (e) {
      debugPrint('Error in getLikesCount: $e');
      return 0;
    }
  }

  // ==================== COMMENT METHODS ====================
  Future<List<Comment>> getComments(String articleId) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, user:users(*)')
          .eq('article_id', articleId)
          .order('created_at', ascending: false);
      
      return response.map<Comment>((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getComments: $e');
      return [];
    }
  }

  Future<void> addComment(String articleId, String userId, String content) async {
    try {
      await _client.from('comments').insert({
        'article_id': articleId,
        'user_id': userId,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error in addComment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('Error in deleteComment: $e');
      rethrow;
    }
  }

  // ==================== SUBSCRIPTION METHODS ====================
  Future<Subscription?> getCurrentSubscription(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error in getCurrentSubscription: $e');
      return null;
    }
  }

  Future<List<Subscription>> getSubscriptionHistory(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Subscription>((json) => Subscription.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getSubscriptionHistory: $e');
      return [];
    }
  }

  Future<void> subscribe(String userId, SubscriptionType type) async {
    try {
      final endDate = DateTime.now().add(Duration(days: type.durationDays));
      final startDate = DateTime.now();
      
      // Désactiver les anciens abonnements
      await _client
          .from('subscriptions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);
      
      // Créer le nouvel abonnement
      await _client.from('subscriptions').insert({
        'user_id': userId,
        'type': type.toString().split('.').last,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'amount': type.price,
        'max_publications': type.maxPublications,
        'has_ads': type.hasAds,
        'is_active': true,
        'publications_used': 0,
      });
    } catch (e) {
      debugPrint('Error in subscribe: $e');
      rethrow;
    }
  }

  Future<void> incrementPublicationsUsed(String subscriptionId) async {
    try {
      // Récupérer l'abonnement actuel
      final subscription = await _client
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();
      
      final currentUsed = subscription['publications_used'] as int? ?? 0;
      
      // Mettre à jour
      await _client
          .from('subscriptions')
          .update({'publications_used': currentUsed + 1})
          .eq('id', subscriptionId);
    } catch (e) {
      debugPrint('Error in incrementPublicationsUsed: $e');
      rethrow;
    }
  }

  Future<int> getUserPublicationsCount(String userId) async {
    try {
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final response = await _client
          .from('articles')
          .select('count')
          .eq('seller_id', userId)
          .gte('created_at', startOfMonth.toIso8601String());
      
      return response.length;
    } catch (e) {
      debugPrint('Error in getUserPublicationsCount: $e');
      return 0;
    }
  }

  // ==================== TRANSACTION METHODS ====================
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await _client.from('transactions').insert(transaction.toJson());
    } catch (e) {
      debugPrint('Error in createTransaction: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final response = await _client
          .from('transactions')
          .select('*, article:articles(*), buyer:users!transactions_buyer_id_fkey(*), seller:users!transactions_seller_id_fkey(*)')
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Transaction>((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getUserTransactions: $e');
      return [];
    }
  }

  Future<void> updateTransaction(String transactionId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('transactions')
          .update(updates)
          .eq('id', transactionId);
    } catch (e) {
      debugPrint('Error in updateTransaction: $e');
      rethrow;
    }
  }
}