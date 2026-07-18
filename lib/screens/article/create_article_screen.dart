import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:cached_network_image/cached_network_image.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/image_picker_grid.dart';
import 'package:http/http.dart' as http;

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _locationController = TextEditingController();
  
  ArticleCategory _selectedCategory = ArticleCategory.pants;
  ArticleColor _selectedColor = ArticleColor.black;
  ArticleCondition _selectedCondition = ArticleCondition.good;
  List<File> _images = [];
  bool _isNegotiable = true;
  bool _isLoading = false;
  bool _isCheckingSubscription = true;
  bool _canPublish = false;
  int _remainingPublications = 0;
  
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    
    setState(() {
      _isCheckingSubscription = true;
    });
    
    try {
      _canPublish = await subscriptionProvider.canPublish(authProvider.user!.id);
      _remainingPublications = await subscriptionProvider.getRemainingPublications(
        authProvider.user!.id,
      );
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      _canPublish = false;
    } finally {
      setState(() {
        _isCheckingSubscription = false;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez ajouter que 3 images maximum'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choisir dans la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile>? pickedImages = await _picker.pickMultiImage();
                if (pickedImages != null) {
                  setState(() {
                    _images.addAll(pickedImages.map((xfile) => File(xfile.path)));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedImage = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (pickedImage != null) {
                  setState(() {
                    _images.add(File(pickedImage.path));
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

// Dans create_article_screen.dart - remplace la section upload

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  if (_images.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez ajouter au moins une image'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (!_canPublish) {
    _showSubscriptionRequiredDialog();
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context, listen: false,
    );

    final supabase = SupabaseService().client;

    // Vérifier la session
    final session = supabase.auth.currentSession;
    debugPrint('🔐 Session: ${session != null ? "OK" : "NULL"}');
    debugPrint('🔐 User: ${supabase.auth.currentUser?.id}');
    if (session == null) {
      throw Exception('Utilisateur non connecté. Reconnectez-vous.');
    }

    // Config Supabase pour HTTP direct
    const String supabaseUrl = 'https://tuskzaagqmittqjgigzm.supabase.co';
    const String anonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1c2t6YWFncW1pdHRxamdpZ3ptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0Mzg2NDAsImV4cCI6MjA5MDAxNDY0MH0.GVgMdQLtOWme6EL-DG8L6scT8lL8AxrJFYTpzLDZBvs';

    List<String> imageUrls = [];

    for (int i = 0; i < _images.length; i++) {
      final file = File(_images[i].path);
      final bytes = await file.readAsBytes();
      final ext = _images[i].path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final fileName =
          '${authProvider.user!.id}_${DateTime.now().millisecondsSinceEpoch}_$i.$safeExt';

      debugPrint('📤 HTTP Upload [$i]: $fileName');
      debugPrint('📁 Taille: ${bytes.length} bytes');

      final uri = Uri.parse(
        '$supabaseUrl/storage/v1/object/article_images/$fileName',
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': anonKey,
          'Content-Type': 'image/$safeExt',
          'x-upsert': 'true',
        },
        body: bytes,
      );

      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl =
            '$supabaseUrl/storage/v1/object/public/article_images/$fileName';
        imageUrls.add(publicUrl);
        debugPrint('✅ URL [$i]: $publicUrl');
      } else {
        throw Exception(
          'Upload échoué (${response.statusCode}): ${response.body}',
        );
      }
    }

    // Créer l'article
    final article = Article(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _selectedCategory,
      brand: _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      size: _sizeController.text.trim(),
      color: _selectedColor,
      condition: _selectedCondition,
      images: imageUrls,
      sellerId: authProvider.user!.id,
      createdAt: DateTime.now(),
      isActive: true,
      views: 0,
      isPromoted: false,
      isNegotiable: _isNegotiable,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
    );

    await articleProvider.createArticle(article);
    await subscriptionProvider.incrementPublicationsUsed(authProvider.user!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article publié avec succès! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _brandController.clear();
      _sizeController.clear();
      _locationController.clear();

      setState(() {
        _images.clear();
        _selectedCategory = ArticleCategory.pants;
        _selectedColor = ArticleColor.black;
        _selectedCondition = ArticleCondition.good;
        _isNegotiable = true;
      });

      Navigator.pop(context);
    }
  } catch (e) {
    debugPrint('❌ Erreur globale: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showSubscriptionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Abonnement requis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous devez avoir un abonnement actif pour publier des articles.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous n\'avez pas d\'abonnement actif ou vous avez atteint votre limite de publications.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('S\'abonner'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier un article'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: const Text(
              'Publier',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isCheckingSubscription
          ? const LoadingWidget(message: 'Vérification de l\'abonnement...')
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subscription warning
                        if (!_canPublish)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.orange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Abonnement requis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Souscrivez à un abonnement pour publier des articles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/subscription');
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                  child: const Text('Voir les offres'),
                                ),
                              ],
                            ),
                          ),
                        
                        // Remaining publications info
                        if (_canPublish && _remainingPublications > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Il vous reste $_remainingPublications publication(s) ce mois-ci',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Images section
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoutez jusqu\'à 3 photos de votre article',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ImagePickerGrid(
                          images: _images,
                          onAdd: _pickImages,
                          onRemove: _removeImage,
                          maxImages: 3,
                        ),
                        const SizedBox(height: 24),
                        
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              const Text(
                                'Titre',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Ex: Jean slim bleu',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un titre';
                                  }
                                  if (value.length < 5) {
                                    return 'Le titre doit contenir au moins 5 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Description
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  hintText: 'Décrivez votre article...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer une description';
                                  }
                                  if (value.length < 10) {
                                    return 'La description doit contenir au moins 10 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Price
                              const Text(
                                'Prix',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  prefixText: 'CFA ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un prix';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null) {
                                    return 'Veuillez entrer un nombre valide';
                                  }
                                  if (price <= 0) {
                                    return 'Le prix doit être supérieur à 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Negotiable switch
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Prix négociable',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Switch(
                                    value: _isNegotiable,
                                    onChanged: (value) {
                                      setState(() {
                                        _isNegotiable = value;
                                      });
                                    },
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Category
                              const Text(
                                'Catégorie',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<ArticleCategory>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    items: ArticleCategory.values.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category.displayName),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedCategory = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Brand
                              const Text(
                                'Marque',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _brandController,
                                decoration: InputDecoration(
                                  hintText: 'Ex: Nike, Zara (optionnel)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Size
                              const Text(
                                'Taille',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _sizeController,
                                decoration: InputDecoration(
                                  hintText: 'Ex: S, M, L, XL, 38, 40',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer une taille';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Color
                              const Text(
                                'Couleur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<ArticleColor>(
                                    value: _selectedColor,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    items: ArticleColor.values.map((color) {
                                      return DropdownMenuItem(
                                        value: color,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: color.colorValue,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.grey),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(color.displayName),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedColor = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Condition
                              const Text(
                                'État',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<ArticleCondition>(
                                    value: _selectedCondition,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    items: ArticleCondition.values.map((condition) {
                                      return DropdownMenuItem(
                                        value: condition,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getConditionIcon(condition),
                                              size: 20,
                                              color: _getConditionColor(condition),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(condition.displayName),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedCondition = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Location
                              const Text(
                                'Localisation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: 'Ex: Lomé, Cotonou (optionnel)',
                                  prefixIcon: const Icon(Icons.location_on, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Loading overlay
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: LoadingWidget(message: 'Publication en cours...'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  IconData _getConditionIcon(ArticleCondition condition) {
    switch (condition) {
      case ArticleCondition.brandNew:
        return Icons.emergency;
      case ArticleCondition.likeNew:
        return Icons.star;
      case ArticleCondition.veryGood:
        return Icons.thumb_up;
      case ArticleCondition.good:
        return Icons.check_circle;
      case ArticleCondition.acceptable:
        return Icons.warning;
    }
  }

  Color _getConditionColor(ArticleCondition condition) {
    switch (condition) {
      case ArticleCondition.brandNew:
        return Colors.green;
      case ArticleCondition.likeNew:
        return Colors.blue;
      case ArticleCondition.veryGood:
        return Colors.teal;
      case ArticleCondition.good:
        return Colors.orange;
      case ArticleCondition.acceptable:
        return Colors.red;
    }
  }
}