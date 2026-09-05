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
  final VoidCallback? onExclusiveActivated;

  const AppShell({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    this.onExclusiveActivated,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Book> books = [];
  bool loading = true;
  bool adBlockCheckComplete = false;
  bool adBlockDetected = false;
  bool exclusiveUnlocked = false;
  String? errorMessage;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExclusiveState();
    _loadBooksThenCheckAdBlocker();
  }

  Future<void> _loadExclusiveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => exclusiveUnlocked = prefs.getBool('exclusive_content_unlocked') ?? false);
    } catch (_) {}
  }

  Future<void> _activateExclusiveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('exclusive_content_unlocked', true);
    } catch (_) {}
    if (!mounted) return;
    setState(() => exclusiveUnlocked = true);
    widget.onExclusiveActivated?.call();
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
      setState(() {
        loading = false;
        adBlockCheckComplete = true;
        errorMessage = 'تعذر تحميل المحتوى.\nتحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
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
        errorMessage = 'تعذر تحميل المحتوى.\nتحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const orange = Color(0xFFF28C28);
    const gold = Color(0xFFC89B3C);
    final accent = exclusiveUnlocked ? gold : orange;
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      indicatorColor: accent.withValues(alpha: 0.18),
      onDestinationSelected: (index) {
        if (currentIndex == index) return;
        setState(() => currentIndex = index);
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: accent), label: 'الرئيسية'),
        NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded, color: accent), label: 'المكتبة'),
        NavigationDestination(icon: const Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded, color: accent), label: 'المفضلة'),
        NavigationDestination(icon: const Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download_rounded, color: accent), label: 'تنزيلاتي'),
      ],
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(color: orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.menu_book_rounded, size: 38, color: orange)),
            const SizedBox(height: 22),
            const Text('كِتارا', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400)),
            const SizedBox(height: 14),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: orange)),
            const SizedBox(height: 14),
            Text('جاري تجهيز مكتبتك...', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
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
    const orange = Color(0xFFF28C28);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: orange.withValues(alpha: 0.10), shape: BoxShape.circle), child: const Icon(Icons.cloud_off_rounded, size: 46, color: orange)),
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
