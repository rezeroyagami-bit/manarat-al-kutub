import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import '../services/ad_block_detector.dart';
import 'ad_block_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import '../widgets/kitara_status_bar.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final Future<void> Function(String code)? onExclusiveActivated;
  final Future<void> Function()? onExclusiveDeactivated;

  const AppShell({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    this.onExclusiveActivated,
    this.onExclusiveDeactivated,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final SupabaseService _supabaseService = SupabaseService();
  List<Book> books = [];
  bool loading = true;
  bool adBlockCheckComplete = false;
  bool adBlockDetected = false;
  bool exclusiveUnlocked = false;
  bool _checkingActivation = false;
  String? errorMessage;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExclusiveState();
    _loadBooksThenCheckAdBlocker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidateActivation();
    }
  }

  Future<void> _loadExclusiveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getBool('exclusive_content_unlocked') ?? false;
      final savedCode = prefs.getString('exclusive_activation_code');
      if (!unlocked || savedCode == null || savedCode.trim().isEmpty) {
        if (!mounted) return;
        setState(() => exclusiveUnlocked = false);
        return;
      }

      try {
        final valid = await _supabaseService.validateKitaraActivationCode(savedCode);
        if (!valid) {
          await _clearExclusiveState();
          return;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => exclusiveUnlocked = true);
    } catch (_) {}
  }

  Future<void> _revalidateActivation() async {
    if (_checkingActivation) return;
    _checkingActivation = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getBool('exclusive_content_unlocked') ?? false;
      final savedCode = prefs.getString('exclusive_activation_code');
      if (!unlocked || savedCode == null || savedCode.trim().isEmpty) {
        if (mounted && exclusiveUnlocked) {
          setState(() => exclusiveUnlocked = false);
          await widget.onExclusiveDeactivated?.call();
        }
        return;
      }

      final valid = await _supabaseService.validateKitaraActivationCode(savedCode);
      if (!valid) {
        await _clearExclusiveState();
      } else if (mounted && !exclusiveUnlocked) {
        setState(() => exclusiveUnlocked = true);
        await widget.onExclusiveActivated?.call(savedCode);
      }
    } catch (_) {} finally {
      _checkingActivation = false;
    }
  }

  Future<void> _clearExclusiveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('exclusive_content_unlocked', false);
      await prefs.remove('exclusive_activation_code');
    } catch (_) {}
    if (!mounted) return;
    setState(() => exclusiveUnlocked = false);
    await widget.onExclusiveDeactivated?.call();
  }

  Future<void> _activateExclusiveTheme(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('exclusive_content_unlocked', true);
      await prefs.setString('exclusive_activation_code', code.trim());
    } catch (_) {}
    if (!mounted) return;
    setState(() => exclusiveUnlocked = true);
    await widget.onExclusiveActivated?.call(code.trim());
  }

  Future<void> _loadBooksThenCheckAdBlocker() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
        adBlockCheckComplete = false;
        adBlockDetected = false;
      });
    }

    try {
      final result = await _supabaseService.getBooks();
      if (!mounted) return;
      setState(() {
        books = result;
        loading = true;
      });

      final blocked = await AdBlockDetector.isLikelyBlocked();
      if (!mounted) return;
      setState(() {
        adBlockDetected = blocked;
        adBlockCheckComplete = true;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // The downloads screen is local and must remain available without internet.
      // Keep any previously loaded books, skip the online ad-block check, and open
      // the normal shell so the user can access downloaded files offline.
      setState(() {
        loading = false;
        adBlockCheckComplete = true;
        adBlockDetected = false;
        errorMessage = null;
      });
    }
  }

  Future<void> loadBooks() async {
    if (mounted) setState(() { loading = true; errorMessage = null; });
    try {
      final result = await _supabaseService.getBooks();
      if (!mounted) return;
      setState(() { books = result; loading = false; errorMessage = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!adBlockCheckComplete || loading) return const _LoadingScreen();
    if (adBlockDetected) return AdBlockScreen(onRetry: _loadBooksThenCheckAdBlocker);
    if (errorMessage != null) return _ErrorScreen(message: errorMessage!, onRetry: _loadBooksThenCheckAdBlocker);

    final screens = <Widget>[
      HomeScreen(books: books, onTheme: widget.onThemeToggle),
      LibraryScreen(books: books),
      FavoritesScreen(books: books, supabaseService: _supabaseService),
      const DownloadsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 7),
            child: Align(
              alignment: Alignment.centerRight,
              child: KitaraStatusBar(
                exclusiveUnlocked: exclusiveUnlocked,
                onActivated: _activateExclusiveTheme,
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: currentIndex, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const orange = Color(0xFFF28C28);
    final accent = exclusiveUnlocked ? orange : green;
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      backgroundColor: accent,
      elevation: 8,
      shadowColor: Colors.black26,
      indicatorColor: Colors.white.withValues(alpha: 0.20),
      onDestinationSelected: (index) {
        if (currentIndex == index) return;
        setState(() => currentIndex = index);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.white70), selectedIcon: Icon(Icons.home_rounded, color: Colors.white), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined, color: Colors.white70), selectedIcon: Icon(Icons.menu_book_rounded, color: Colors.white), label: 'المكتبة'),
        NavigationDestination(icon: Icon(Icons.favorite_border_rounded, color: Colors.white70), selectedIcon: Icon(Icons.favorite_rounded, color: Colors.white), label: 'المفضلة'),
        NavigationDestination(icon: Icon(Icons.download_outlined, color: Colors.white70), selectedIcon: Icon(Icons.download_rounded, color: Colors.white), label: 'تنزيلاتي'),
      ],
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(color: green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.menu_book_rounded, size: 38, color: green)),
            const SizedBox(height: 22),
            const Text('كِتارا', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400)),
            const SizedBox(height: 14),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: green)),
            const SizedBox(height: 14),
            Text('جاري تجهيز مكتبتك...', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: green.withValues(alpha: 0.10), shape: BoxShape.circle), child: const Icon(Icons.cloud_off_rounded, size: 46, color: green)),
            const SizedBox(height: 24),
            const Text('تعذر تحميل المحتوى', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.grey)),
            const SizedBox(height: 26),
            SizedBox(width: 190, child: ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة'))),
          ]),
        ),
      ),
    );
  }
}
