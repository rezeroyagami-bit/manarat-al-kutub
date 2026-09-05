import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'services/supabase_config.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool savedDarkMode = false;
  bool savedExclusiveTheme = false;
  bool supabaseReady = false;

  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
    supabaseReady = true;
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    savedDarkMode = prefs.getBool('dark_mode') ?? false;
    savedExclusiveTheme = prefs.getBool('exclusive_content_unlocked') ?? false;
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
  }

  runApp(KitaraApp(
    initialDarkMode: savedDarkMode,
    initialExclusiveTheme: savedExclusiveTheme,
    supabaseReady: supabaseReady,
  ));
  _initializeAdsSafely();
}

Future<void> _initializeAdsSafely() async {
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization error: $e');
  }
}

class KitaraApp extends StatefulWidget {
  final bool initialDarkMode;
  final bool initialExclusiveTheme;
  final bool supabaseReady;

  const KitaraApp({
    super.key,
    required this.initialDarkMode,
    required this.initialExclusiveTheme,
    required this.supabaseReady,
  });

  @override
  State<KitaraApp> createState() => _KitaraAppState();
}

class _KitaraAppState extends State<KitaraApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late bool isDarkMode;
  late bool isExclusiveTheme;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    isExclusiveTheme = widget.initialExclusiveTheme;
    _playIntro();
  }

  Future<void> _playIntro() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _audioPlayer.play(AssetSource('kitara_intro.wav'));
    } catch (e) {
      debugPrint('Intro audio error: $e');
    }
  }

  Future<void> toggleTheme() async {
    if (!mounted) return;
    setState(() => isDarkMode = !isDarkMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDarkMode);
    } catch (e) {
      debugPrint('Theme save error: $e');
    }
  }

  Future<void> activateExclusiveTheme() async {
    if (!mounted) return;
    setState(() => isExclusiveTheme = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('exclusive_content_unlocked', true);
    } catch (e) {
      debugPrint('Exclusive theme save error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) {
    const orange = Color(0xFFF28C28);
    const gold = Color(0xFFC89B3C);
    final accent = isExclusiveTheme ? gold : orange;
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Amiri',
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness),
      scaffoldBackgroundColor: dark ? const Color(0xFF121212) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: dark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF1E1E1E) : Colors.white,
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w600)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(color: states.contains(WidgetState.selected) ? accent : Colors.grey);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KITARA — كِتارا',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: widget.supabaseReady ? const WelcomeScreen() : const SupabaseErrorScreen(),
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
      final appState = context.findAncestorStateOfType<_KitaraAppState>();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            onThemeToggle: appState?.toggleTheme ?? () {},
            isDarkMode: appState?.isDarkMode ?? false,
            onExclusiveActivated: appState?.activateExclusiveTheme,
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/kitara_icon.png', width: 120, height: 120, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const SizedBox(width: 120, height: 120, child: Icon(Icons.menu_book, size: 80, color: orange))),
                const SizedBox(height: 24),
                const Text('KITARA', style: TextStyle(fontFamily: 'Amiri', fontSize: 38, fontWeight: FontWeight.bold, color: orange, letterSpacing: 2)),
                const SizedBox(height: 6),
                const Text('كِتارا', style: TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                const Text('رحلة الكتاب تبدأ بصفحة', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 10),
                const Text('اقرأ • استكشف • استمتع', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SupabaseErrorScreen extends StatelessWidget {
  const SupabaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off_rounded, size: 70, color: orange),
            const SizedBox(height: 20),
            const Text('تعذر تشغيل كِتارا', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('تعذر تهيئة الاتصال بالخادم.\nتحقق من اتصال الإنترنت ثم أعد تشغيل التطبيق.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.7, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
