import 'package:flutter/material.dart';

import '../models/book.dart';
import 'details_screen.dart';

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
  static const redOrange = Color(0xFFE85D2A);
  static const green = Color(0xFF2E9D59);

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

      final title = book.title.toLowerCase();
      final author = book.author.toLowerCase();
      final category = book.category.toLowerCase();

      final matchesSearch =
          title.contains(query) ||
          author.contains(query) ||
          category.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get categories {
    final values = widget.books
        .map((book) => book.category)
        .where((category) => category.trim().isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final books = filteredBooks;

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
        onRefresh: () async {
          await Future.delayed(
            const Duration(milliseconds: 500),
          );

          if (mounted) {
            setState(() {});
          }
        },

        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

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
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },

                        textInputAction:
                            TextInputAction.search,

                        decoration: InputDecoration(
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

                    const SizedBox(height: 22),

                    // الأكثر قراءة وتحميلاً
                    if (searchText.isEmpty)
                      _sectionHeader(
                        title: '🔥 الأكثر قراءة وتحميلًا',
                        onTap: () {},
                      ),

                    if (searchText.isEmpty)
                      const SizedBox(height: 12),

                    if (searchText.isEmpty &&
                        widget.books.isNotEmpty)
                      SizedBox(
                        height: 235,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              widget.books.length > 6
                                  ? 6
                                  : widget.books.length,

                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),

                          itemBuilder: (context, index) {
                            return _FeaturedBookCard(
                              book: widget.books[index],
                              onTap: () => openBook(
                                widget.books[index],
                              ),
                            );
                          },
                        ),
                      ),

                    if (searchText.isEmpty)
                      const SizedBox(height: 26),

                    // الأقسام
                    if (searchText.isEmpty)
                      _sectionHeader(
                        title: '📚 تصفح حسب القسم',
                        onTap: () {},
                      ),

                    if (searchText.isEmpty)
                      const SizedBox(height: 12),

                    if (searchText.isEmpty)
                      SizedBox(
                        height: 45,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,

                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),

                          itemBuilder: (context, index) {
                            final category =
                                categories[index];

                            final selected =
                                selectedCategory ==
                                    category;

                            return ChoiceChip(
                              label: Text(category),

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

                              labelStyle: TextStyle(
                                fontWeight:
                                    selected
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

                    // عنوان المحتوى
                    _sectionHeader(
                      title: searchText.isNotEmpty
                          ? 'نتائج البحث'
                          : selectedCategory == 'الكل'
                              ? '🆕 أحدث المحتوى'
                              : selectedCategory,
                      onTap: () {},
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // شبكة الكتب
            if (books.isEmpty)
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];

                      return _BookCard(
                        book: book,
                        onTap: () => openBook(book),
                      );
                    },

                    childCount: books.length,
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
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        TextButton(
          onPressed: onTap,
          child: const Text(
            'عرض الكل',
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// بطاقة المحتوى الرئيسية
// ------------------------------------------------------------

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.onTap,
  });

  static const orange = Color(0xFFF28C28);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,

        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,

            borderRadius: BorderRadius.circular(20),

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

          child: Padding(
            padding: const EdgeInsets.all(9),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(14),

                    child: book.coverUrl != null &&
                            book.coverUrl!.isNotEmpty
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,

                            errorBuilder:
                                (_, __, ___) {
                              return _CoverPlaceholder();
                            },
                          )
                        : _CoverPlaceholder(),
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
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// البطاقة البارزة
// ------------------------------------------------------------

class _FeaturedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _FeaturedBookCard({
    required this.book,
    required this.onTap,
  });

  static const orange = Color(0xFFF28C28);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 150,

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,

          child: Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,

              borderRadius:
                  BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(15),

                    child: book.coverUrl != null &&
                            book.coverUrl!.isNotEmpty
                        ? Image.network(
                            book.coverUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    _CoverPlaceholder(),
                          )
                        : _CoverPlaceholder(),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: const [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: orange,
                    ),

                    SizedBox(width: 3),

                    Text(
                      'شائع',
                      style: TextStyle(
                        fontSize: 11,
                        color: orange,
                        fontWeight: FontWeight.bold,
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
// صورة غلاف بديلة
// ------------------------------------------------------------

class _CoverPlaceholder extends StatelessWidget {
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
// حالة عدم وجود نتائج
// ------------------------------------------------------------

class _EmptyState extends StatelessWidget {
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

              color: const Color(
                0xFFF28C28,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              hasSearch
                  ? 'لم نجد ما تبحث عنه'
                  : 'لا توجد كتب حاليًا',

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
