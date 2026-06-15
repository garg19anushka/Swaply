import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/post_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/swap_service.dart';
import 'screens/splash_screen.dart';
import 'screens/swaps/all_swaps_screen.dart';
import 'screens/posts/create_post_screen.dart';
import 'utils/app_theme.dart';
import 'services/leaderboard_service.dart';

// ← Remove the home_screen import from main.dart entirely.
// HomeScreen is navigated to FROM SplashScreen, not set here directly.

const String supabaseUrl = 'https://yxmmuyfbanwqfsyqfyug.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4bW11eWZiYW53cWZzeXFmeXVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3OTQ5MTUsImV4cCI6MjA5MTM3MDkxNX0.B6tCiP3wkgyPR0HTl17bDyNNjR-kNAY2aTrVh7zOiSY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const Swaply());
}

final supabase = Supabase.instance.client;

class Swaply extends StatelessWidget {
  const Swaply({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PostService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
        ChangeNotifierProvider(create: (_) => SwapService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            title: 'Swaply',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              '/my_swaps': (_) => const AllSwapsScreen(),
              '/create_post': (_) => const CreatePostScreen(),
            },
            home:
                const SplashScreen(), // ← Keep this. SplashScreen routes to HomeScreen after auth.
          );
        },
      ),
    );
  }
}
