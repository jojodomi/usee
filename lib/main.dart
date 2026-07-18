// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/article_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/souscription/subscription_screen.dart';
import 'screens/souscription/subscription_history_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/my_articles_screen.dart';
import 'screens/article/create_article_screen.dart';
import 'screens/article/edit_article_screen.dart';
import 'screens/article/article_detail_screen.dart';
import 'screens/payment/payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Charger les variables d'environnement depuis .env
  await dotenv.load(fileName: ".env");
  
  // Vérifier que les variables sont présentes
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      '⚠️ Variables SUPABASE_URL et SUPABASE_ANON_KEY doivent être définies dans .env'
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'Used',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Gestionnaire de routes personnalisé
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            case '/login':
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            case '/subscription':
              return MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              );
            case '/subscription-history':
              return MaterialPageRoute(
                builder: (context) => const SubscriptionHistoryScreen(),
              );
            case '/edit-profile':
              final args = settings.arguments as Map?;
              return MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  user: args?['user'],
                ),
              );
            case '/my-articles':
              return MaterialPageRoute(
                builder: (context) => const MyArticlesScreen(),
              );
            case '/sell':
              return MaterialPageRoute(
                builder: (context) => const CreateArticleScreen(),
              );
            case '/article-detail':
              final args = settings.arguments as Map?;
              return MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(
                  articleId: args?['articleId'] ?? '',
                ),
              );
            case '/edit-article':
              final args = settings.arguments as Map?;
              return MaterialPageRoute(
                builder: (context) => EditArticleScreen(
                  article: args?['article'],
                ),
              );
            case '/payment':
              final args = settings.arguments as Map?;
              return MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  article: args?['article'],
                  amount: args?['amount'],
                  description: args?['description'],
                  customerName: args?['customerName'],
                  customerPhone: args?['customerPhone'],
                  customerEmail: args?['customerEmail'],
                  onSuccess: args?['onSuccess'],
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Page non trouvée'),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (authProvider.user != null) {
      return const HomeScreen();
    }
    
    return const LoginScreen();
  }
}