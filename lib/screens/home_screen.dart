import 'package:flutter/material.dart';

import '../models/book.dart';
import 'details_screen.dart';
import 'about_screen.dart';

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

  void openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
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

                    // البحث
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

                    // نتائج البحث
                    if (searchText.isNotEmpty) ...[
                      _sectionHeader(
                        title: 'نتائج البحث',
                      ),
                      const SizedBox(height: 12),
                    ],

                    // الأقسام
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

                      // الكتب
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

                      // المجلات القديمة
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
                          height: 330,
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
                                    openBook(magazine),
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

            // نتائج البحث / أحدث المحتوى
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
                        onTap: () => openBook(book),
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
              child: _Cover(
                url: book.coverUrl,
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

  String get magazineDescription {
    if (book.title.contains('العربي الصغير')) {
      return 'مجلة العربي الصغير هي نافذة ثقافية ساحرة وأيقونة أدب الأطفال في العالم العربي. تصدر شهرياً عن وزارة الإعلام الكويتية منذ عام 1986، لتأخذ القراء الصغار في رحلة ممتعة تجمع بين العلوم والفنون والقصص المصورة.';
    }

    if (book.description != null &&
        book.description!.trim().isNotEmpty) {
      return book.description!;
    }

    return 'مجلة قديمة من مجموعة KITARA.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return SizedBox(
      width: 245,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.15 : 0.07,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 165,
                  child: _Cover(
                    url: book.coverUrl,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  book.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  magazineDescription,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),

                const SizedBox(height: 6),

                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 15,
                      color: orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'مجلة',
                      style: TextStyle(
                        color: orange,
                        fontSize: 12,
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
            child: _Cover(
              url: book.coverUrl,
            ),
          ),

          const SizedBox(height: 9),

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

          const SizedBox(height: 2),

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
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.15 : 0.07,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
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
    if (url == null || url!.isEmpty) {
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

class _CoverPlaceholder
    extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F3F3),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 48,
          color: Color(0xFFF28C28),
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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
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
        padding: const EdgeInsets.all(30),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasSearch
                  ? 'جرّب البحث بعنوان أو مؤلف مختلف.'
                  : 'سيظهر المحتوى هنا عند إضافته.',
              textAlign: TextAlign.center,
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
