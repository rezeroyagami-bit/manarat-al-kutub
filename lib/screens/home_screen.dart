import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import '../services/remote_config.dart';
import '../services/app_update_service.dart';
import 'about_screen.dart';
import 'details_screen.dart';
import 'magazine_screen.dart';
import 'support_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Book> books;
  final VoidCallback onTheme;

  const HomeScreen({super.key, required this.books, required this.onTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  String selectedCategory = 'الكل';
  List<String> _newsItems = [];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService().showUpdateDialog(context);
    });
  }

  Future<void> _loadNews() async {
    try {
      final items = await SupabaseService().getNewsTicker();
      if (!mounted) return;
      setState(() {
        _newsItems = items.map((item) => item['text'] as String).where((text) => text.trim().isNotEmpty).toList();
        _loadingNews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newsItems = [];
        _loadingNews = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get filteredBooks {
    final query = searchText.trim().toLowerCase();
    return widget.books.where((book) {
      final categoryMatches = selectedCategory == RemoteConfigStore.instance.config.allCategoryTitle || book.category == selectedCategory;
      if (!categoryMatches) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) || book.author.toLowerCase().contains(query) || book.category.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get categories {
    final values = widget.books.map((book) => book.category.trim()).where((value) => value.isNotEmpty).toSet().toList()..sort();
    return [RemoteConfigStore.instance.config.allCategoryTitle, ...values];
  }

  Future<void> _openBook(Book book) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(book: book)));
  }

  Future<void> _openMagazine(Book book) async {
    var name = book.title.trim();
    if (name.contains(' — العدد')) name = name.split(' — العدد').first.trim();
    if (name.startsWith('مجلة ')) name = name.substring(5).trim();
    try {
      final magazine = await SupabaseService().getMagazineByName(name);
      if (!mounted) return;
      if (magazine == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر العثور على بيانات المجلة.')));
        return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MagazineScreen(
        magazineId: magazine['id'] as String,
        magazineName: magazine['name'] as String,
        description: magazine['description'] as String?,
        coverUrl: magazine['cover_url'] as String?,
      )));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح المجلة. تحقق من اتصال الإنترنت.')));
    }
  }

  void _openAbout() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
  void _openSupport() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));

  bool _isIssueOne(String title) {
    return RegExp(r'العدد\s*(?:1|١)(?:\D|$)').hasMatch(title.trim());
  }

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigStore.instance.config;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final results = filteredBooks;
    final books = results.where((book) => !book.isMagazine).toList();
    final hiddenOldMagazines = (config.values['hide_from_old_magazines_ids'] ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final magazines = results.where((book) => book.isMagazine && !hiddenOldMagazines.contains(book.id) && _isIssueOne(book.title)).toList();
    final hiddenLatestContentIds = (config.values['hide_from_latest_content_ids'] ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final latestResults = searchText.trim().isEmpty
        ? results.where((book) => !hiddenLatestContentIds.contains(book.id)).take(4).toList()
        : results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كِتارا'),
        actions: [
          IconButton(onPressed: _openSupport, icon: const Icon(Icons.volunteer_activism_outlined)),
          IconButton(onPressed: _openAbout, icon: const Icon(Icons.info_outline_rounded)),
          IconButton(onPressed: widget.onTheme, icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن كتاب أو مجلة...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchText.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchText = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
                onChanged: (value) => setState(() => searchText = value),
              ),
            ),
          ),
          if (_loadingNews)
            const SliverToBoxAdapter(child: SizedBox(height: 4))
          else if (_newsItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: accent.withValues(alpha: 0.08),
                  ),
                  child: Text(_newsItems.first, textDirection: TextDirection.rtl),
                ),
              ),
            ),
          if (searchText.trim().isEmpty) ...[
            _sectionHeader('أحدث محتوى'),
            _booksSection(latestResults, accent),
            _sectionHeader('المجلات القديمة'),
            _booksSection(magazines, accent),
          ] else ...[
            _sectionHeader('نتائج البحث'),
            _booksSection(results, accent),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Text(title, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      );

  SliverPadding _booksSection(List<Book> books, Color accent) {
    if (books.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        sliver: SliverToBoxAdapter(child: Text('لا يوجد محتوى متاح حاليًا.', textDirection: TextDirection.rtl)),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            return GestureDetector(
              onTap: () => book.isMagazine ? _openMagazine(book) : _openBook(book),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _Cover(url: book.coverUrl, accent: accent)),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: books.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String url;
  final Color accent;
  const _Cover({required this.url, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(color: accent.withValues(alpha: 0.08), child: Icon(Icons.menu_book_rounded, size: 52, color: accent));
    }
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.08), child: Icon(Icons.menu_book_rounded, size: 52, color: accent)));
  }
}
