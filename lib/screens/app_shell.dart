import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import '../services/ad_block_detector.dart';
import 'ad_block_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const AppShell({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Book> books = [];
  bool loading = true;
  bool adBlockCheckComplete = false;
  bool adBlockDetected = false;
  String? errorMessage;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBooksThenCheckAdBlocker();
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
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    const orange = Color(0xFFF28C28);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      indicatorColor: orange.withValues(alpha: 0.18),
      onDestinationSelected: (index) {
        if (currentIndex == index) return;
        setState(() => currentIndex = index);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'المكتبة'),
        NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'المفضلة'),
        NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download_rounded), label: 'تنزيلاتي'),
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
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 38, color: orange),
            ),
            const SizedBox(height: 22),
            const Text(
              'كِتارا',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: orange),
            ),
            const SizedBox(height: 14),
            Text(
              'جاري تجهيز مكتبتك...',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
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
