import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../widgets/article_card.dart';
import '../../widgets/filters_dialog.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../article/article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadArticles() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.loadArticles(refresh: true);
  }

 void _onScroll() {
  if (!_scrollController.hasClients) return;
  final provider = Provider.of<ArticleProvider>(context, listen: false);
 
  // ✅ Utilise isLoadingMore au lieu de isLoading
  if (provider.isLoadingMore || !provider.hasMore) return;
 
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    provider.loadMoreArticles();
  }
}

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FiltersDialog(
        onApply: (filters) {
          final provider = Provider.of<ArticleProvider>(context, listen: false);
          provider.applyFilters(filters);
        },
      ),
    );
  }

  void _onArticleTap(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(articleId: article.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<ArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un article...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  provider.searchArticles(value);
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : const Text('Used'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  provider.clearFilters();
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        child: _buildBody(provider),
      ),
    );
  }

 Widget _buildBody(ArticleProvider provider) {
  if (provider.isLoading && provider.articles.isEmpty) {
    return const LoadingWidget();
  }
 
  if (provider.articles.isEmpty) {
    return const EmptyStateWidget(
      icon: Icons.inventory,
      message: 'Aucun article trouvé',
      subtitle: 'Soyez le premier à publier un article',
    );
  }
 
  return GridView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.7,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    // ✅ Spinner uniquement si isLoadingMore (pas isLoading global)
    itemCount: provider.articles.length + (provider.isLoadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == provider.articles.length) {
        return const Center(child: CircularProgressIndicator());
      }
      final article = provider.articles[index];
      return ArticleCard(
        article: article,
        onTap: () => _onArticleTap(article),
      );
    },
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}