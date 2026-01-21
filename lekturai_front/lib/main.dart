import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lekturai_front/firebase_options.dart';
import 'package:lekturai_front/history_screen.dart';
import 'package:lekturai_front/matura_questions_screen.dart';
import 'package:lekturai_front/reading_question_screen.dart';
import 'package:lekturai_front/register_screen.dart';
import 'package:lekturai_front/widgets/auth_wrapper.dart';
import 'package:lekturai_front/widgets/loading_screen.dart';
import 'package:lekturai_front/services/notification_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'essay_assistant_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lektur.AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Professional Blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      // Define routes
      routes: {
        '/': (context) => const AppInitializer(),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/zlektur': (context) =>
            const ReadingQuestionsScreen(readingName: "Lalka"),
        '/zmatur': (context) => const QuestionsScreen(),
        '/rozprawka': (context) => const EssayAssistantScreen(),
        '/historia': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      initialRoute: '/',
    );
  }
}

/// Handles app initialization with beautiful loading screen
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables (optional - don't crash if file doesn't exist)
      try {
        await dotenv.load(fileName: "assets/.env");
        print('✓ Environment variables loaded');
      } catch (e) {
        print('Warning: Could not load .env file: $e');
        // Continue without .env file - will use defaults
      }

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✓ Firebase initialized');

      // Initialize notification service
      await NotificationService().initialize();
      print('✓ Notifications initialized');

      // Add a minimum delay for smooth experience
      await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate to auth wrapper
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      print('Error initializing app: $e');
      // Show error and retry option
      if (mounted) {
        _showInitializationError(e.toString());
      }
    }
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Błąd inicjalizacji'),
        content: Text(
          'Nie udało się zainicjalizować aplikacji:\n\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen(
      message: 'Inicjalizacja aplikacji...',
    );
  }
}
