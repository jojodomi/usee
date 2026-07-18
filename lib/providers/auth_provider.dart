// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      await loadUser();
    }
  }

  Future<void> _saveUserToStorage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> _clearUserStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print('📝 AuthProvider: Début inscription');
      
      final response = await _supabaseService.signUp(
        email,
        password,
        fullName,
        phone,
      );
      
      if (response.user != null) {
        print('✅ Inscription réussie, tentative de connexion automatique');
        await signIn(email: email, password: password);
      } else {
        print('⚠️ Inscription sans utilisateur');
        _setLoading(false);
      }
    } catch (e) {
      print('❌ Erreur inscription: $e');
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print('🔐 AuthProvider: Début connexion pour: $email');
      
      final session = await _supabaseService.signIn(email, password);
      
      if (session.user != null) {
        print('✅ Session obtenue, chargement utilisateur...');
        await loadUser();
        
        if (_user != null) {
          await _saveUserToStorage(session.user!.id);
          print('✅ Utilisateur sauvegardé dans storage');
        } else {
          print('⚠️ Utilisateur chargé est null');
        }
      } else {
        print('⚠️ Session sans utilisateur');
      }
      
      _setLoading(false);
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _supabaseService.signOut();
      _user = null;
      await _clearUserStorage();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUser() async {
    try {
      print('📱 Chargement utilisateur...');
      _user = await _supabaseService.getCurrentUser();
      print('✅ Utilisateur chargé: ${_user?.fullName ?? 'null'}');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadUser: $e');
      _error = e.toString();
      _user = null;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? address,
    String? avatarUrl,
  }) async {
    _setLoading(true);

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (address != null) updates['address'] = address;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabaseService.updateUser(_user!.id, updates);
      await loadUser();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> upgradeUserType(UserType newType) async {
    _setLoading(true);

    try {
      await _supabaseService.updateUser(_user!.id, {
        'user_type': newType.apiValue,
      });
      await loadUser();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}