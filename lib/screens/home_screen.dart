import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import '../services/favorites_service.dart';
import 'details_screen.dart';
import 'about_screen.dart';
import 'magazine_screen.dart';
import 'support_screen.dart';
import 'favorites_screen.dart';

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
  final TextEditingController _searchController =
      TextEditingController();

  String searchText = '';
  String selectedCategory = 'الكل';

  static const orange = Color(0xFFF28C28);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get filteredBooks {
    final query = searchText.trim().toLowerCase();

    return widget.books.where((book) {
      final matchesCategory =
          selectedCategory == 'الكل' ||
          book.category == selectedCategory;

      if (query.isEmpty) {
        return matchesCategory;
      }

      return matchesCategory &&
          (book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query) ||
              book.category.toLowerCase().contains(query));
    }).toList();
  }

  List<Book> get booksOnly =>
      filteredBooks.where((book) => !book.isMagazine).toList();

  List<Book> get magazinesOnly =>
      filteredBooks.where((book) => book.isMagazine).toList();

  List<String> get categories {
    final values = widget.books
        .map((book) => book.category)
        .where(
          (category) => category.trim().isNotEmpty,
        )
        .toSet()
        .toList();

    values.sort();

    return ['الكل', ...values];
  }

  void openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(book: book),
      ),
    );
  }

  Future<void> openMagazine(Book book) async {
    String magazineName = book.title.trim();

    if (magazineName.contains(' — العدد')) {
      magazineName =
          magazineName.split(' — العدد').first.trim();
    }

    if (magazineName.startsWith('مجلة ')) {
      magazineName =
          magazineName.substring(5).trim();
    }

    try {
      final service = SupabaseService();

      final magazine =
          await service.getMagazineByName(magazineName);

      if (!mounted) return;

      if (magazine == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر العثور على بيانات المجلة.',
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MagazineScreen(
            magazineId: magazine['id'] as String,
            magazineName:
                magazine['name'] as String,
            description:
                magazine['description'] as String?,
            coverUrl:
                magazine['cover_url'] as String?,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح المجلة. تحقق من اتصال الإنترنت.',
          ),
        ),
      );
    }
  }

  void openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  void openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupportScreen(),
      ),
    );
  }

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          books: widget.books,
        ),
      ),
    );
  }

  Future<void> refreshContent() async {
    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final results = filteredBooks;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'KITARA — كِتارا',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'الدعم والشكاوى',
            onPressed: openSupport,
            icon: const Icon(
              Icons.support_agent_rounded,
              color: orange,
            ),
          ),

          IconButton(
            tooltip: 'المفضلة',
            onPressed: openFavorites,
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: orange,
            ),
          ),

          IconButton(
            tooltip: 'حول كِتارا',
            onPressed: openAbout,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: orange,
            ),
          ),

          IconButton(
            tooltip:
                isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: widget.onTheme,
            icon: Icon(
              isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: orange,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        color: orange,
        onRefresh: refreshContent,

        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا بك في كِتارا',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'اقرأ • استكشف • استمتع',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black12,
                        ),
                      ),
                      child: TextField(
                        controller:
                            _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        textInputAction:
                            TextInputAction.search,
                        decoration:
                            InputDecoration(
                          hintText:
                              'ابحث عن كتاب أو مجلة أو مؤلف...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                          ),
                          suffixIcon:
                              searchText.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController
                                            .clear();

                                        setState(() {
                                          searchText = '';
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                      ),
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            vertical: 17,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (searchText.isNotEmpty) ...[
                      _sectionHeader(
                        title: 'نتائج البحث',
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (searchText.isEmpty) ...[
                      _sectionHeader(
                        title: 'تصفح حسب القسم',
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 46,
                        child: ListView.separated(
                          scrollDirection:
                              Axis.horizontal,
                          itemCount:
                              categories.length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            width: 8,
                          ),
                          itemBuilder:
                              (context, index) {
                            final category =
                                categories[index];

                            final selected =
                                selectedCategory ==
                                    category;

                            return ChoiceChip(
                              label:
                                  Text(category),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategory =
                                      category;
                                });
                              },
                              selectedColor:
                                  orange.withValues(
                                alpha: 0.18,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? orange
                                    : Colors.grey
                                        .withValues(
                                      alpha: 0.25,
                                    ),
                              ),
                              labelStyle:
                                  TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? orange
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      _sectionHeader(
                        title: 'الكتب',
                      ),

                      const SizedBox(height: 12),

                      if (booksOnly.isEmpty)
                        const _SmallEmptyState(
                          text:
                              'لا توجد كتب مضافة حاليًا.',
                        )
                      else
                        SizedBox(
                          height: 265,
                          child: ListView.separated(
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                booksOnly.length,
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(
                              width: 14,
                            ),
                            itemBuilder:
                                (context, index) {
                              final book =
                                  booksOnly[index];

                              return _BookHorizontalCard(
                                book: book,
                                onTap: () =>
                                    openBook(book),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 30),

                      _sectionHeader(
                        title: 'المجلات القديمة',
                      ),

                      const SizedBox(height: 12),

                      if (magazinesOnly.isEmpty)
                        const _SmallEmptyState(
                          text:
                              'لا توجد مجلات مضافة حاليًا.',
                        )
                      else
                        SizedBox(
                          height: 280,
                          child: ListView.separated(
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                magazinesOnly.length,
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(
                              width: 14,
                            ),
                            itemBuilder:
                                (context, index) {
                              final magazine =
                                  magazinesOnly[index];

                              return _MagazineCard(
                                book: magazine,
                                onTap: () =>
                                    openMagazine(magazine),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 30),

                      _sectionHeader(
                        title: 'أحدث المحتوى',
                      ),

                      const SizedBox(height: 14),
                    ],

                    if (searchText.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  hasSearch:
                      searchText.trim().isNotEmpty,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  28,
                ),
                sliver: SliverGrid(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) {
                      final book = results[index];

                      return _BookCard(
                        book: book,
                        onTap: () {
                          if (book.isMagazine) {
                            openMagazine(book);
                          } else {
                            openBook(book);
                          }
                        },
                      );
                    },
                    childCount: results.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _sectionHeader({
    required String title,
  }) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ------------------------------------------------------------
// زر المفضلة
// ------------------------------------------------------------

class _FavoriteButton extends StatefulWidget {
  final String bookId;

  const _FavoriteButton({
    required this.bookId,
  });

  @override
  State<_FavoriteButton> createState() =>
      _FavoriteButtonState();
}

class _FavoriteButtonState
    extends State<_FavoriteButton> {
  final FavoritesService _favoritesService =
      FavoritesService();

  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final value =
        await _favoritesService.isFavorite(widget.bookId);

    if (!mounted) return;

    setState(() {
      isFavorite = value;
      isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (isLoading) return;

    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      await _favoritesService
          .toggleFavorite(widget.bookId);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isFavorite = !isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر حفظ المفضلة.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavorite
                ? const Color(0xFFF28C28)
                : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// بطاقة الكتب الأفقية
// ------------------------------------------------------------

class _BookHorizontalCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookHorizontalCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return SizedBox(
      width: 155,
      child: _CardContainer(
        isDark: isDark,
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _Cover(
                      url: book.coverUrl,
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: _FavoriteButton(
                      bookId: book.id,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white60
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// بطاقة المجلة
// ------------------------------------------------------------

class _MagazineCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _MagazineCard({
    required this.book,
    required this.onTap,
  });

  static const orange = Color(0xFFF28C28);

  String get magazineName {
    String name = book.title.trim();

    if (name.contains(' — العدد')) {
      name = name.split(' — العدد').first.trim();
    }

    if (name.startsWith('مجلة ')) {
      name = name.substring(5).trim();
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return SizedBox(
      width: 210,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha:
                        isDark ? 0.15 : 0.07,
                  ),
                  blurRadius: 12,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _Cover(
                          url: book.coverUrl,
                        ),
                      ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: _FavoriteButton(
                          bookId: book.id,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  magazineName,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 17,
                      color: orange,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'عرض المجلة',
                      style: TextStyle(
                        color: orange,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// البطاقة الرئيسية
// ------------------------------------------------------------

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return _CardContainer(
      isDark: isDark,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _Cover(
                    url: book.coverUrl,
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: _FavoriteButton(
                    bookId: book.id,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          Text(
            book.title,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            book.author,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white60
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------

class _CardContainer extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;

  const _CardContainer({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha:
                      isDark ? 0.15 : 0.07,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------

class _Cover extends StatelessWidget {
  final String? url;

  const _Cover({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null ||
        url!.trim().isEmpty) {
      return const _CoverPlaceholder();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                const _CoverPlaceholder(),
      ),
    );
  }
}

// ------------------------------------------------------------

class _CoverPlaceholder
    extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          const Color(0xFFF3F3F3),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 48,
          color:
              Color(0xFFF28C28),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------

class _SmallEmptyState
    extends StatelessWidget {
  final String text;

  const _SmallEmptyState({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      width: double.infinity,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(
              alpha: 0.35,
            ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------

class _EmptyState
    extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({
    required this.hasSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.menu_book_rounded,
              size: 70,
              color:
                  const Color(0xFFF28C28),
            ),

            const SizedBox(height: 18),

            Text(
              hasSearch
                  ? 'لم نجد ما تبحث عنه'
                  : 'لا يوجد محتوى حاليًا',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasSearch
                  ? 'جرّب البحث بعنوان أو مؤلف مختلف.'
                  : 'سيظهر المحتوى هنا عند إضافته.',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
