import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/article_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../article/edit_article_screen.dart';
import '../article/article_detail_screen.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  State<MyArticlesScreen> createState() => _MyArticlesScreenState();
}

class _MyArticlesScreenState extends State<MyArticlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Article> _activeArticles = [];
  List<Article> _inactiveArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArticles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    
    await provider.loadUserArticles(authProvider.user!.id);
    
    setState(() {
      _activeArticles = provider.userArticles.where((a) => a.isActive).toList();
      _inactiveArticles = provider.userArticles.where((a) => !a.isActive).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteArticle(Article article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet article?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = Provider.of<ArticleProvider>(context, listen: false);
      await provider.deleteArticle(article.id);
      await _loadArticles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleArticleStatus(Article article) async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.updateArticle(article.id, {
      'is_active': !article.isActive,
    });
    await _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes articles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Actifs (${_activeArticles.length})'),
            Tab(text: 'Archivés (${_inactiveArticles.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildArticlesList(_activeArticles, isActive: true),
                _buildArticlesList(_inactiveArticles, isActive: false),
              ],
            ),
    );
  }

  Widget _buildArticlesList(List<Article> articles, {required bool isActive}) {
    if (articles.isEmpty) {
      return EmptyStateWidget(
        icon: isActive ? Icons.inventory : Icons.archive,
        message: isActive 
            ? 'Aucun article actif' 
            : 'Aucun article archivé',
        subtitle: isActive
            ? 'Publiez votre premier article dès maintenant'
            : 'Les articles que vous archivez apparaîtront ici',
        onAction: isActive
            ? () {
                Navigator.pushNamed(context, '/sell');
              }
            : null,
        actionLabel: isActive ? 'Publier un article' : null,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ArticleCard(
                article: article,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(articleId: article.id),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditArticleScreen(article: article),
                            ),
                          ).then((_) => _loadArticles());
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleArticleStatus(article),
                        icon: Icon(
                          isActive ? Icons.archive : Icons.unarchive,
                          size: 18,
                        ),
                        label: Text(isActive ? 'Archiver' : 'Réactiver'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteArticle(article),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}