import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import 'details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Book> books;

  const FavoritesScreen({
    super.key,
    required this.books,
  });

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  Set<String> favoriteIds = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList('favorite_books') ?? [];

    if (!mounted) return;

    setState(() {
      favoriteIds = saved.toSet();
      loading = false;
    });
  }

  Future<void> _removeFavorite(Book book) async {
    final prefs =
        await SharedPreferences.getInstance();

    final updated = {...favoriteIds}
      ..remove(book.id.toString());

    await prefs.setStringList(
      'favorite_books',
      updated.toList(),
    );

    if (!mounted) return;

    setState(() {
      favoriteIds = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إزالة الكتاب من المفضلة',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final favoriteBooks = widget.books
        .where(
          (book) =>
              favoriteIds.contains(
            book.id.toString(),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المفضلة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: favoriteBooks.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteBooks.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final book =
                      favoriteBooks[index];

                  return _FavoriteCard(
                    book: book,
                    onRemove: () =>
                        _removeFavorite(book),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailsScreen(
                            book: book,
                          ),
                        ),
                      );

                      _loadFavorites();
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    const orange = Color(0xFFF28C28);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                    orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: orange,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'المفضلة فارغة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'أضف الكتب التي تعجبك إلى المفضلة\n'
              'لتجدها هنا بسهولة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Book book;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.book,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // الغلاف
              SizedBox(
                width: 62,
                height: 82,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: book.coverUrl != null &&
                          book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Container(
                            color: orange.withValues(
                              alpha: 0.10,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: orange,
                            ),
                          ),
                        )
                      : Container(
                          color: orange.withValues(
                            alpha: 0.10,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: orange,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      book.author,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: orange.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(
                        book.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: orange,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // زر إزالة
              IconButton(
                onPressed: onRemove,
                tooltip: 'إزالة من المفضلة',
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
