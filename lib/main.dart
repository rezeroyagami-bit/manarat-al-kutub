import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import 'services/supabase_config.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const KitaraApp());
}

class KitaraApp extends StatefulWidget {
  const KitaraApp({super.key});

  @override
  State<KitaraApp> createState() => _KitaraAppState();
}

class _KitaraAppState extends State<KitaraApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _playIntro();
  }

  Future<void> _playIntro() async {
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      await _audioPlayer.play(
        AssetSource('kitara_intro.wav'),
      );
    } catch (_) {
      // يستمر التطبيق بشكل طبيعي إذا تعذر تشغيل الصوت.
    }
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KITARA — كيتارا',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: orange.withValues(alpha: 0.18),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: orange);
              }
              return const IconThemeData(color: Colors.grey);
            },
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: orange.withValues(alpha: 0.25),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: orange);
              }
              return const IconThemeData(color: Colors.grey);
            },
          ),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      final appState =
          context.findAncestorStateOfType<_KitaraAppState>();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            onThemeToggle: appState?.toggleTheme ?? () {},
            isDarkMode: appState?.isDarkMode ?? false,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/kitara_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'KITARA',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: orange,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'كيتارا',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'مرحبًا بك في عالم الكتب',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
