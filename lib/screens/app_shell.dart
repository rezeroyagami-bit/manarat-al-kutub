import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import '../services/remote_config.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'maintenance_screen.dart';

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
  bool exclusiveUnlocked = true;
  bool maintenanceMode = false;
  bool maintenanceAllowDownloads = true;
  bool _checkingActivation = false;
  bool _checkingMaintenance = false;
  String maintenanceTitle = 'كِتارا قيد الصيانة';
  String maintenanceMessage = 'نعمل حاليًا على تحسين كِتارا وتحديث المحتوى. يرجى المحاولة لاحقًا.';
  String? errorMessage;
  int currentIndex = 0;
  final GlobalKey<DownloadsScreenState> _downloadsKey = GlobalKey<DownloadsScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RemoteConfigStore.instance.addListener(_onRemoteConfigChanged);
    _loadBooks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RemoteConfigStore.instance.removeListener(_onRemoteConfigChanged);
    super.dispose();
  }

  void _onRemoteConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMaintenance();
      RemoteConfigStore.instance.load();
    }
  }

  Future<void> _checkMaintenance({bool showLoading = false}) async {
    if (_checkingMaintenance) return;
    _checkingMaintenance = true;
    try {
      final settings = await _supabaseService.getMaintenanceSettings();
      final mode = settings['maintenance_mode']?.toLowerCase() == 'true';
      final allowDownloads = settings['maintenance_allow_downloads']?.toLowerCase() != 'false';
      final title = settings['maintenance_title']?.trim();
      final message = settings['maintenance_message']?.trim();

      if (!mounted) return;
      setState(() {
        maintenanceMode = mode;
        maintenanceAllowDownloads = allowDownloads;
        if (title != null && title.isNotEmpty) maintenanceTitle = title;
        if (message != null && message.isNotEmpty) maintenanceMessage = message;
      });
    } catch (_) {
      // A temporary network failure must never lock the user out of local downloads.
    } finally {
      _checkingMaintenance = false;
    }
  }

  Future<void> _loadBooks() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      await _checkMaintenance();
      if (maintenanceMode) {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
        return;
      }

      final result = await _supabaseService.getBooks();
      if (!mounted) return;
      setState(() {
        books = result;
        loading = true;
      });

      if (!mounted) return;
      setState(() { loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = null;
      });
    }
  }

  Future<void> loadBooks() async {
    if (mounted) setState(() { loading = true; errorMessage = null; });
    try {
      await _checkMaintenance();
      if (maintenanceMode) {
        if (!mounted) return;
        setState(() { loading = false; errorMessage = null; });
        return;
      }
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

  void _openDownloadsFromMaintenance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingScreen();

    if (maintenanceMode) {
      if (maintenanceAllowDownloads) {
        return MaintenanceScreen(
          title: maintenanceTitle,
          message: maintenanceMessage,
          onDownloads: _openDownloadsFromMaintenance,
        );
      }
      return _MaintenanceLockedScreen(
        title: maintenanceTitle,
        message: maintenanceMessage,
      );
    }

    if (errorMessage != null) return _ErrorScreen(message: errorMessage!, onRetry: _loadBooks);

    final screens = <Widget>[
      HomeScreen(books: books, onTheme: widget.onThemeToggle),
      LibraryScreen(books: books),
      FavoritesScreen(books: books, supabaseService: _supabaseService),
      DownloadsScreen(key: _downloadsKey),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final config = RemoteConfigStore.instance.config;
    const accent = Color(0xFFF28C28);
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      backgroundColor: accent,
      elevation: 8,
      shadowColor: Colors.black26,
      indicatorColor: Colors.white.withValues(alpha: 0.20),
      onDestinationSelected: (index) {
        if (index == 3) _downloadsKey.currentState?.refreshDownloads();
        if (currentIndex == index) return;
        setState(() => currentIndex = index);
      },
      destinations: [
        NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.white70), selectedIcon: Icon(Icons.home_rounded, color: Colors.white), label: config.navHome),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined, color: Colors.white70), selectedIcon: Icon(Icons.menu_book_rounded, color: Colors.white), label: config.navLibrary),
        NavigationDestination(icon: Icon(Icons.favorite_border_rounded, color: Colors.white70), selectedIcon: Icon(Icons.favorite_rounded, color: Colors.white), label: config.navFavorites),
        NavigationDestination(icon: Icon(Icons.download_outlined, color: Colors.white70), selectedIcon: Icon(Icons.download_rounded, color: Colors.white), label: config.navDownloads),
      ],
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(color: green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.menu_book_rounded, size: 38, color: green)),
            const SizedBox(height: 22),
            const Text('كِتارا', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400)),
            const SizedBox(height: 14),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: green)),
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
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: green.withValues(alpha: 0.10), shape: BoxShape.circle), child: Icon(Icons.cloud_off_rounded, size: 46, color: green)),
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

class _MaintenanceLockedScreen extends StatelessWidget {
  final String title;
  final String message;
  const _MaintenanceLockedScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, size: 70, color: green),
                const SizedBox(height: 22),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Amiri', fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.7, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
