import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/supabase_config.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final savedDarkMode = prefs.getBool('dark_mode') ?? false;

  runApp(
    KitaraApp(initialDarkMode: savedDarkMode),
  );
}

class KitaraApp extends StatefulWidget {
  final bool initialDarkMode;

  const KitaraApp({
    super.key,
    required this.initialDarkMode,
  });

  @override
  State<KitaraApp> createState() => _KitaraAppState();
}

class _KitaraAppState extends State<KitaraApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  late bool isDarkMode;

  @override
  void initState() {
    super.initState();

    isDarkMode = widget.initialDarkMode;

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

  Future<void> toggleTheme() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'dark_mode',
      isDarkMode,
    );
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

      title: 'KITARA — كِتارا',

      themeMode: isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Amiri',

        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,

          indicatorColor: Color(0x2EF28C28),

          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w600,
            ),
          ),

          iconTheme: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: orange,
                );
              }

              return const IconThemeData(
                color: Colors.grey,
              );
            },
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Amiri',

        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor: const Color(0xFF121212),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),

          indicatorColor: Color(0x40F28C28),

          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w600,
            ),
          ),

          iconTheme: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: orange,
                );
              }

              return const IconThemeData(
                color: Colors.grey,
              );
            },
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        final appState =
            context.findAncestorStateOfType<_KitaraAppState>();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AppShell(
              onThemeToggle:
                  appState?.toggleTheme ?? () {},
              isDarkMode:
                  appState?.isDarkMode ?? false,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

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
                    fontFamily: 'Amiri',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: orange,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'كِتارا',

                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'رحلة الكتاب تبدأ بصفحة',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'اقرأ • استكشف • استمتع',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
