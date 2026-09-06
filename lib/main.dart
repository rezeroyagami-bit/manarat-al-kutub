import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'services/remote_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitaraApp());
}

class KitaraApp extends StatefulWidget {
  const KitaraApp({super.key});

  @override
  State<KitaraApp> createState() => _KitaraAppState();
}

class _KitaraAppState extends State<KitaraApp> {
  bool isDarkMode = false;
  bool exclusiveUnlocked = false;

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  void activateExclusiveTheme() {
    setState(() => exclusiveUnlocked = true);
  }

  void deactivateExclusiveTheme() {
    setState(() => exclusiveUnlocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigStore.instance.config;
    final accent = exclusiveUnlocked
        ? config.exclusivePrimaryColor
        : config.freePrimaryColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appTitle,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        fontFamily: 'Amiri',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Amiri',
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
      final appState = context.findAncestorStateOfType<_KitaraAppState>();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            onThemeToggle: appState?.toggleTheme ?? () {},
            isDarkMode: appState?.isDarkMode ?? false,
            onExclusiveActivated: appState?.activateExclusiveTheme,
            onExclusiveDeactivated: appState?.deactivateExclusiveTheme,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigStore.instance.config;
    final green = config.freePrimaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/kitara_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: 120,
                    height: 120,
                    child: Icon(Icons.menu_book, size: 80, color: green),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'KITARA',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: green,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.brandArabic,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  config.introTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  config.introSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
