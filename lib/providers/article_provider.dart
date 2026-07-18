import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/supabase_service.dart';

class ArticleProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Article> _articles = [];
  List<Article> _favoriteArticles = [];
  List<Article> _userArticles = [];
  Map<String, bool> _likesStatus = {};
  Map<String, int> _likesCount = {};

  // ✅ États de chargement séparés pour ne pas polluer isLoading global
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingUserArticles = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _searchQuery;
  Map<String, dynamic>? _currentFilters;

  // Getters
  List<Article> get articles => _articles;
  List<Article> get favoriteArticles => _favoriteArticles;
  List<Article> get userArticles => _userArticles;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  Map<String, bool> get likesStatus => _likesStatus;
  Map<String, int> get likesCount => _likesCount;

  ArticleProvider() {
    loadArticles();
  }

  Future<void> loadArticles({bool refresh = false}) async {
    if (_isLoading) return; // ✅ Guard contre les appels simultanés

    if (refresh) {
      _currentPage = 0;
      _articles.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newArticles = await _supabaseService.getArticles(
        limit: 20,
        offset: _currentPage * 20,
        category: _currentFilters?['category'],
        minPrice: _currentFilters?['minPrice'],
        maxPrice: _currentFilters?['maxPrice'],
        color: _currentFilters?['color'],
        brand: _currentFilters?['brand'],
        size: _currentFilters?['size'],
        searchQuery: _searchQuery,
      );

      if (newArticles.length < 20) {
        // ✅ Si moins de 20 résultats → plus rien à charger
        _hasMore = false;
      }

      if (newArticles.isNotEmpty) {
        _articles.addAll(newArticles);
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Error loading articles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreArticles() async {
    // ✅ Guards stricts : ne rien faire si déjà en chargement
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newArticles = await _supabaseService.getArticles(
        limit: 20,
        offset: _currentPage * 20,
        category: _currentFilters?['category'],
        minPrice: _currentFilters?['minPrice'],
        maxPrice: _currentFilters?['maxPrice'],
        color: _currentFilters?['color'],
        brand: _currentFilters?['brand'],
        size: _currentFilters?['size'],
        searchQuery: _searchQuery,
      );

      if (newArticles.length < 20) {
        _hasMore = false;
      }

      if (newArticles.isNotEmpty) {
        _articles.addAll(newArticles);
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Error loading more articles: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ✅ CORRIGÉ : état de chargement séparé, ne touche pas _isLoading global
  Future<void> loadUserArticles(String userId) async {
    _isLoadingUserArticles = true;
    notifyListeners();

    try {
      _userArticles = await _supabaseService.getUserArticles(userId);
    } catch (e) {
      debugPrint('Error loading user articles: $e');
    } finally {
      _isLoadingUserArticles = false;
      notifyListeners();
    }
  }

  // ✅ CORRIGÉ : état de chargement séparé
  Future<void> loadFavoriteArticles(String userId) async {
    try {
      _favoriteArticles = await _supabaseService.getFavoriteArticles(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorite articles: $e');
    }
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _currentFilters = filters;
    await loadArticles(refresh: true);
  }

  Future<void> searchArticles(String query) async {
    _searchQuery = query.isNotEmpty ? query : null;
    await loadArticles(refresh: true);
  }

  Future<void> createArticle(Article article) async {
    try {
      await _supabaseService.createArticle(article);
      await loadArticles(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateArticle(id, data);
      await loadArticles(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _supabaseService.deleteArticle(id);
      _articles.removeWhere((article) => article.id == id);
      _userArticles.removeWhere((article) => article.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike(String articleId, String userId) async {
    final isLiked = _likesStatus[articleId] ?? false;

    try {
      if (isLiked) {
        await _supabaseService.unlikeArticle(articleId, userId);
        _likesStatus[articleId] = false;
        _likesCount[articleId] = (_likesCount[articleId] ?? 1) - 1;
      } else {
        await _supabaseService.likeArticle(articleId, userId);
        _likesStatus[articleId] = true;
        _likesCount[articleId] = (_likesCount[articleId] ?? 0) + 1;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> loadLikeStatus(String articleId, String userId) async {
    try {
      final isLiked = await _supabaseService.isLiked(articleId, userId);
      _likesStatus[articleId] = isLiked;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading like status: $e');
    }
  }

  Future<void> loadLikesCount(String articleId) async {
    try {
      final count = await _supabaseService.getLikesCount(articleId);
      _likesCount[articleId] = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading likes count: $e');
    }
  }

  Future<Article?> getArticleById(String id) async {
    try {
      return await _supabaseService.getArticleById(id);
    } catch (e) {
      debugPrint('Error getting article: $e');
      return null;
    }
  }

  Future<void> incrementViews(String articleId) async {
    try {
      await _supabaseService.incrementViews(articleId);
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  void clearFilters() {
    _currentFilters = null;
    _searchQuery = null;
    loadArticles(refresh: true);
  }
}