import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vacathon_mobile/screens/register_screen.dart';
import 'providers/auth_provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/events_screen.dart';
import 'screens/admin_event_management_screen.dart';
import 'screens/admin_participant_management_screen.dart';
import 'screens/admin_forum_moderation_screen.dart';

// App Colors
const Color primaryGreen = Color(0xFFB9F61E);
const Color primaryBlue = Color(0xFF006DDA);
const Color secondaryGreen = Color(0xFF8BC34A);
const Color accentOrange = Color(0xFFFF9800);
const Color backgroundLight = Color(0xFFF5F5F5);

void main() {
  runApp(
    MultiProvider(
      providers: [
        // 1. Provider CookieRequest (Root untuk auth)
        Provider(
          create: (_) {
            CookieRequest request = CookieRequest();
            return request;
          },
        ),
        // 2. AuthProvider sekarang bergantung pada CookieRequest
        // Kita gunakan ChangeNotifierProxyProvider untuk menyuntikkan request ke AuthProvider
        ChangeNotifierProxyProvider<CookieRequest, AuthProvider>(
          // Gunakan CookieRequest() kosong sebagai inisial, JANGAN null
          create: (_) => AuthProvider(CookieRequest()),

          // Saat request yang asli dari Provider tersedia, update AuthProvider
          update: (_, request, authProvider) => AuthProvider(request),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vacathon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
          primary: primaryBlue,
          secondary: primaryGreen,
          tertiary: accentOrange,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundLight,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        // Admin routes - accessible from main dashboard
        '/admin/events': (context) => const AdminEventManagementScreen(),
        '/admin/participants': (context) =>
            const AdminParticipantManagementScreen(),
        '/admin/forum': (context) => const AdminForumModerationScreen(),
        // Routes are now handled by bottom navigation in HomeScreen
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      // All users (including admins) go to the main dashboard
      // Admin features are shown within the main dashboard for admin users
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
