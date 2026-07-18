import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/article.dart';
//import '../../models/interaction.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comment_section.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/loading_widget.dart';
import '../payment/payment_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  
  const ArticleDetailScreen({
    super.key,
    required this.articleId,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<Article?> _articleFuture;
  int _selectedImageIndex = 0;
  bool _isLiked = false;
  int _likesCount = 0;
  Article? _article;

  @override
  void initState() {
    super.initState();
    _loadArticle();
    _loadInteractions();
  }

  void _loadArticle() {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    _articleFuture = provider.getArticleById(widget.articleId);
    _articleFuture.then((article) {
      if (article != null && mounted) {
        setState(() {
          _article = article;
        });
        provider.incrementViews(widget.articleId);
      }
    });
  }

  Future<void> _loadInteractions() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await provider.loadLikeStatus(widget.articleId, authProvider.user!.id);
      if (mounted) {
        setState(() {
          _isLiked = provider.likesStatus[widget.articleId] ?? false;
        });
      }
    }
    
    await provider.loadLikesCount(widget.articleId);
    if (mounted) {
      setState(() {
        _likesCount = provider.likesCount[widget.articleId] ?? 0;
      });
    }
  }

  void _toggleLike() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour aimer'),
        ),
      );
      return;
    }
    
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    
    await provider.toggleLike(widget.articleId, authProvider.user!.id);
  }

  void _showImageGallery(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(images[index]),
                  initialScale: PhotoViewComputedScale.contained,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: PageController(initialPage: initialIndex),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyNow(Article article) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour acheter'),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          article: article,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Article?>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erreur lors du chargement de l\'article'),
            );
          }
          
          final article = snapshot.data!;
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () => _showImageGallery(article.images, 0),
                    child: PageView.builder(
                      itemCount: article.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: article.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleLike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Implement share functionality
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image indicator
                      if (article.images.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            article.images.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedImageIndex == index
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Title and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                article.formattedPrice,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (article.hasDiscount)
                                Text(
                                  article.formattedOriginalPrice,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating and sales
                      Row(
                        children: [
                          const RatingStars(rating: 4.5),
                          const SizedBox(width: 8),
                          Text(
                            '(${article.seller?.totalSales ?? 0} ventes)',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Condition
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: article.condition.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: article.condition.color),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(article.condition.icon, size: 14, color: article.condition.color),
                            const SizedBox(width: 4),
                            Text(
                              article.condition.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: article.condition.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Seller info
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: article.seller?.avatarUrl != null
                                ? CachedNetworkImageProvider(article.seller!.avatarUrl!)
                                : null,
                            child: article.seller?.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(article.seller?.fullName ?? 'Vendeur'),
                          subtitle: Text(article.seller?.userTypeDisplay ?? ''),
                          trailing: OutlinedButton(
                            onPressed: () {
                              // Navigate to seller profile
                            },
                            child: const Text('Contacter'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Details
                      const Text(
                        'Détails',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Catégorie', article.category.displayName),
                      if (article.brand != null)
                        _buildDetailRow('Marque', article.brand!),
                      _buildDetailRow('Taille', article.size),
                      _buildDetailRow('Couleur', article.color.displayName),
                      _buildDetailRow('État', article.condition.displayName),
                      if (article.location != null)
                        _buildDetailRow('Localisation', article.location!),
                      if (article.isNegotiable)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '💰 Prix négociable',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.description,
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      // Comments section
                      CommentSection(articleId: article.id),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _article != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Show contact options
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _buyNow(_article!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Acheter',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(': $value'),
        ],
      ),
    );
  }
}