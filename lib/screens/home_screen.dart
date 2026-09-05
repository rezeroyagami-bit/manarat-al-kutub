import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import 'about_screen.dart';
import 'details_screen.dart';
import 'magazine_screen.dart';
import 'support_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Book> books;
  final VoidCallback onTheme;

  const HomeScreen({
    super.key,
    required this.books,
    required this.onTheme,
  });

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
  }

  Future<void> _loadNews() async {
    try {
      final items = await SupabaseService().getNewsTicker();
      if (!mounted) return;
      setState(() {
        _newsItems = items
            .map((item) => item['text'] as String)
            .where((text) => text.trim().isNotEmpty)
            .toList();
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
      final categoryMatches = selectedCategory == 'الكل' || book.category == selectedCategory;
      if (!categoryMatches) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get categories {
    final values = widget.books
        .map((book) => book.category.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['الكل', ...values];
  }

  Future<void> _openBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(book: book)),
    );
  }

  Future<void> _openMagazine(Book book) async {
    var name = book.title.trim();
    if (name.contains(' — العدد')) name = name.split(' — العدد').first.trim();
    if (name.startsWith('مجلة ')) name = name.substring(5).trim();
    try {
      final magazine = await SupabaseService().getMagazineByName(name);
      if (!mounted) return;
      if (magazine == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر العثور على بيانات المجلة.')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MagazineScreen(
            magazineId: magazine['id'] as String,
            magazineName: magazine['name'] as String,
            description: magazine['description'] as String?,
            coverUrl: magazine['cover_url'] as String?,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المجلة. تحقق من اتصال الإنترنت.')),
      );
    }
  }

  void _openAbout() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  void _openSupport() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final results = filteredBooks;
    final books = results.where((book) => !book.isMagazine).toList();
    final magazines = results.where((book) => book.isMagazine).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'KITARA — كِتارا',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: 'الدعم والشكاوى',
            onPressed: _openSupport,
            icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'حول كِتارا',
            onPressed: _openAbout,
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: widget.onTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: accent,
        onRefresh: _loadNews,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحبًا بك في كِتارا',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اقرأ • استكشف • استمتع',
                      style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    if (!_loadingNews && _newsItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NewsTicker(items: _newsItems, accent: accent),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E241E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accent.withValues(alpha: 0.28)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => searchText = value),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن كتاب أو مجلة أو مؤلف...',
                          prefixIcon: Icon(Icons.search_rounded, color: accent),
                          suffixIcon: searchText.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => searchText = '');
                                  },
                                  icon: Icon(Icons.close_rounded, color: accent),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: searchText.isEmpty ? 'تصفح حسب القسم' : 'نتائج البحث'),
                    if (searchText.isEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 46,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final category = categories[index];
                            final selected = category == selectedCategory;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) => setState(() => selectedCategory = category),
                              selectedColor: accent.withValues(alpha: 0.18),
                              side: BorderSide(color: selected ? accent : accent.withValues(alpha: 0.25)),
                              labelStyle: TextStyle(
                                color: selected ? accent : null,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'الكتب'),
                      const SizedBox(height: 12),
                      books.isEmpty
                          ? _EmptyBox(text: 'لا توجد كتب مضافة حاليًا.')
                          : SizedBox(
                              height: 265,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (_, index) => SizedBox(
                                  width: 155,
                                  child: _BookCard(book: books[index], onTap: () => _openBook(books[index])),
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
                      _SectionTitle(title: 'المجلات القديمة'),
                      const SizedBox(height: 12),
                      magazines.isEmpty
                          ? _EmptyBox(text: 'لا توجد مجلات مضافة حاليًا.')
                          : SizedBox(
                              height: 280,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: magazines.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (_, index) => SizedBox(
                                  width: 210,
                                  child: _MagazineCard(book: magazines[index], onTap: () => _openMagazine(magazines[index])),
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
                      _SectionTitle(title: 'أحدث المحتوى'),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(hasSearch: searchText.trim().isNotEmpty, accent: accent),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      final book = results[index];
                      return _BookCard(
                        book: book,
                        onTap: () => book.isMagazine ? _openMagazine(book) : _openBook(book),
                      );
                    },
                    childCount: results.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.64,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      );
}

class _NewsTicker extends StatefulWidget {
  final List<String> items;
  final Color accent;
  const _NewsTicker({required this.items, required this.accent});

  @override
  State<_NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.items.join('     •     ');
    return Container(
      height: 35,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(7)),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => LayoutBuilder(
          builder: (_, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              textDirection: TextDirection.rtl,
            )..layout();
            final total = painter.width + constraints.maxWidth;
            final offset = _controller.value * total;
            return Stack(
              children: [
                Positioned(
                  left: -painter.width + offset,
                  top: 0,
                  child: SizedBox(
                    width: painter.width,
                    height: 35,
                    child: Center(
                      child: Text(text, maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E241E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.07), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _Cover(url: book.coverUrl, accent: accent)),
                    Positioned(top: 7, right: 7, child: _FavoriteButton(bookId: book.id)),
                    if (book.isExclusive)
                      Positioned(
                        left: 7,
                        top: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.workspace_premium_rounded, size: 19, color: accent),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MagazineCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _MagazineCard({required this.book, required this.onTap});

  String get name {
    var value = book.title.trim();
    if (value.contains(' — العدد')) value = value.split(' — العدد').first.trim();
    if (value.startsWith('مجلة ')) value = value.substring(5).trim();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E241E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.07), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _Cover(url: book.coverUrl, accent: accent)),
                    Positioned(top: 7, right: 7, child: _FavoriteButton(bookId: book.id)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 17, color: accent),
                  const SizedBox(width: 5),
                  Text('عرض المجلة', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final String bookId;
  const _FavoriteButton({required this.bookId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  final FavoritesService _service = FavoritesService();
  bool favorite = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _service.isFavorite(widget.bookId);
    if (!mounted) return;
    setState(() {
      favorite = value;
      loading = false;
    });
  }

  Future<void> _toggle() async {
    if (loading) return;
    setState(() => favorite = !favorite);
    try {
      await _service.toggleFavorite(widget.bookId);
    } catch (_) {
      if (!mounted) return;
      setState(() => favorite = !favorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: favorite ? accent : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? url;
  final Color accent;
  const _Cover({required this.url, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
    );
  }

  Widget _placeholder() => Container(
        color: accent.withValues(alpha: 0.08),
        child: Center(child: Icon(Icons.menu_book_rounded, size: 48, color: accent)),
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        height: 75,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        ),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final Color accent;
  const _EmptyState({required this.hasSearch, required this.accent});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(hasSearch ? Icons.search_off_rounded : Icons.menu_book_rounded, size: 70, color: accent),
              const SizedBox(height: 18),
              Text(
                hasSearch ? 'لم نجد ما تبحث عنه' : 'لا يوجد محتوى حاليًا',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch ? 'جرّب البحث بعنوان أو مؤلف مختلف.' : 'سيظهر المحتوى هنا عند إضافته.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
