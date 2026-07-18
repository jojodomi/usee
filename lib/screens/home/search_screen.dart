import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../widgets/article_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../article/article_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Article> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  final List<String> _recentSearches = [
    'Nike Air Max',
    'Robe soirée',
    'Sac à main',
    'Jean slim',
    'Chemise homme',
  ];
  
  final List<Map<String, dynamic>> _popularCategories = [
    {'name': 'Pantalon', 'icon': Icons.shopping_bag, 'color': 0xFF4CAF50},
    {'name': 'Jupe', 'icon': Icons.shopping_bag, 'color': 0xFFFF9800},
    {'name': 'Talons', 'icon': Icons.shopping_bag, 'color': 0xFFE91E63},
    {'name': 'Robe', 'icon': Icons.shopping_bag, 'color': 0xFF9C27B0},
    {'name': 'Chemise', 'icon': Icons.shopping_bag, 'color': 0xFF2196F3},
    {'name': 'Chaussures', 'icon': Icons.shopping_bag, 'color': 0xFF00BCD4},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    await provider.searchArticles(query);
    
    setState(() {
      _searchResults = provider.articles;
      _isSearching = false;
    });
    
    // Save to recent searches
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _searchResults = [];
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Rechercher un article...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const LoadingWidget(message: 'Recherche en cours...');
    }
    
    if (_hasSearched) {
      if (_searchResults.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.search_off,
          message: 'Aucun résultat trouvé',
          subtitle: 'Essayez avec d\'autres mots-clés',
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final article = _searchResults[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ArticleCard(
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
          );
        },
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: const Text('Effacer tout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((search) {
                return Chip(
                  label: Text(search),
                  onDeleted: () {
                    setState(() {
                      _recentSearches.remove(search);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Popular categories
          const Text(
            'Catégories populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: _popularCategories.map((category) {
              return GestureDetector(
                onTap: () {
                  _performSearch(category['name']);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(category['color']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        size: 32,
                        color: Color(category['color']),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Popular brands
          const Text(
            'Marques populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Nike', 'Adidas', 'Zara', 'H&M', 'Gucci',
              'Louis Vuitton', 'Chanel', 'Dior', 'Prada',
            ].map((brand) {
              return ActionChip(
                label: Text(brand),
                onPressed: () => _performSearch(brand),
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}