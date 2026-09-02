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

  runApp(const ManaratApp());
}

class ManaratApp extends StatefulWidget {
  const ManaratApp({super.key});

  @override
  State<ManaratApp> createState() => _ManaratAppState();
}

class _ManaratAppState extends State<ManaratApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      // إذا تعذر تشغيل الصوت، يستمر التطبيق بشكل طبيعي.
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KITARA — كيتارا',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4B3F72),
        scaffoldBackgroundColor: const Color(0xFFF8F7FB),
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AppShell(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 90,
              color: Color(0xFF4B3F72),
            ),
            const SizedBox(height: 24),
            const Text(
              'KITARA',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B3F72),
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
            const Text(
              'مرحبًا بك في عالم الكتب',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
