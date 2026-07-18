// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/article.dart';
import '../../providers/auth_provider.dart';
import '../../providers/article_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/article_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_articles_screen.dart';
import '../souscription/subscription_screen.dart';
import '../souscription/subscription_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  List<Article> _userArticles = [];
  bool _isLoading = true;
  bool _isLoadingArticles = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // ✅ addPostFrameCallback garantit que le build est terminé avant _loadData
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    // ✅ Récupérer les providers AVANT tout await (pendant le frame courant)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingArticles = true;
      _error = null;
    });

    await _loadUser(authProvider);
    if (_user != null) {
      await _loadUserArticles(articleProvider);
    }
  }

  Future<void> _loadUser(AuthProvider authProvider) async {
    try {
      final supabase = SupabaseService().client;

      if (widget.userId != null) {
        // Profil d'un autre utilisateur
        debugPrint('👤 Chargement profil userId: ${widget.userId}');
        final response = await supabase
            .from('users')
            .select()
            .eq('id', widget.userId!)
            .maybeSingle();

        if (mounted) {
          setState(() {
            if (response != null) {
              _user = AppUser.fromJson(response);
              debugPrint('✅ Profil chargé: ${_user!.fullName}');
            } else {
              _error = 'Utilisateur introuvable (id: ${widget.userId})';
              debugPrint('❌ $_error');
            }
            _isLoading = false;
          });
        }
      } else {
        // Mon propre profil
        debugPrint('👤 Chargement mon profil: ${authProvider.user?.id}');

        if (authProvider.user == null) {
          // Tenter de recharger depuis Supabase
          final currentUser = supabase.auth.currentUser;
          if (currentUser == null) {
            if (mounted) {
              setState(() {
                _error = 'Non connecté. Veuillez vous reconnecter.';
                _isLoading = false;
              });
            }
            return;
          }

          final response = await supabase
              .from('users')
              .select()
              .eq('id', currentUser.id)
              .maybeSingle();

          if (mounted) {
            setState(() {
              if (response != null) {
                _user = AppUser.fromJson(response);
                debugPrint('✅ Profil rechargé: ${_user!.fullName}');
              } else {
                _error = 'Profil introuvable. Veuillez vous reconnecter.';
                debugPrint('❌ $_error');
              }
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _user = authProvider.user;
              _isLoading = false;
              debugPrint('✅ Profil depuis provider: ${_user!.fullName}');
            });
          }
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Erreur _loadUser: $e');
      debugPrint('📍 Stack: $stack');
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserArticles(ArticleProvider provider) async {
    if (_user == null) return;

    try {
      await provider.loadUserArticles(_user!.id);

      if (mounted) {
        setState(() {
          _userArticles = provider.userArticles;
          _isLoadingArticles = false;
          debugPrint('✅ ${_userArticles.length} articles chargés');
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur _loadUserArticles: $e');
      if (mounted) {
        setState(() {
          _userArticles = [];
          _isLoadingArticles = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesGrid() {
    if (_isLoadingArticles) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.inventory,
          message: 'Aucun article publié',
          subtitle: 'Commencez à vendre dès maintenant',
          onAction: () => Navigator.pushNamed(context, '/sell'),
          actionLabel: 'Publier un article',
        ),
      );
    }

    final displayCount = _userArticles.length > 6 ? 6 : _userArticles.length;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final article = _userArticles[index];
            return ArticleCard(
              article: article,
              onTap: () => Navigator.pushNamed(
                context,
                '/article-detail',
                arguments: {'articleId': article.id},
              ),
            );
          },
          childCount: displayCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                // ✅ Affiche l'erreur détaillée pour faciliter le debug
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // ✅ Bouton de reconnexion si l'erreur est liée à l'auth
                if (_error!.contains('connecté') || _error!.contains('introuvable'))
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    ),
                    child: const Text('Se reconnecter'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non trouvé')),
      );
    }

    final isOwnProfile = widget.userId == null;
    final totalViews = _userArticles.fold<int>(
      0,
      (sum, article) => sum + article.views,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade400,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _user!.avatarUrl != null
                            ? NetworkImage(_user!.avatarUrl!)
                            : null,
                        child: _user!.avatarUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user!.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user!.userTypeDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isOwnProfile)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(user: _user!),
                          ),
                        ).then((_) => _loadData());
                        break;
                      case 'subscription':
                        Navigator.pushNamed(context, '/subscription');
                        break;
                      case 'history':
                        Navigator.pushNamed(context, '/subscription-history');
                        break;
                      case 'logout':
                        _handleLogout();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Modifier profil'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'subscription',
                      child: Row(children: [
                        Icon(Icons.subscriptions, size: 20),
                        SizedBox(width: 12),
                        Text('Abonnement'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 12),
                        Text('Historique'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Déconnexion',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.shopping_bag,
                        value: (_user!.totalSales ?? 0).toString(),
                        label: 'Ventes',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.favorite,
                        value: '0',
                        label: 'Favoris',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.visibility,
                        value: totalViews.toString(),
                        label: 'Vues',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                    const Text('À propos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_user!.bio!, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 24),
                  ],

                  const Text('Informations de contact',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: const Text('Téléphone'),
                    subtitle: Text(_user!.phone),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.green),
                    title: const Text('Email'),
                    subtitle: Text(_user!.email),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_user!.address != null)
                    ListTile(
                      leading:
                          const Icon(Icons.location_on, color: Colors.green),
                      title: const Text('Adresse'),
                      subtitle: Text(_user!.address!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mes articles',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isOwnProfile)
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/my-articles'),
                          child: const Text('Voir tout'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _buildArticlesGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}