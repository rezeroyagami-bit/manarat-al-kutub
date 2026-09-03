import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/magazine_issue.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import 'details_screen.dart';
import 'download_options_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Book> books;
  final SupabaseService supabaseService;

  const FavoritesScreen({
    super.key,
    required this.books,
    required this.supabaseService,
  });

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService =
      FavoritesService();

  Set<String> favoriteIds = {};

  List<Book> favoriteBooks = [];
  List<MagazineIssue> favoriteIssues = [];

  bool loading = true;

  static const orange = Color(0xFFF28C28);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final saved =
          await _favoritesService.getFavorites();

      final booksResult = widget.books
          .where(
            (book) => saved.contains(book.id),
          )
          .toList();

      final List<MagazineIssue> allIssues = [];

      final magazines =
          await widget.supabaseService.getMagazines();

      for (final magazine in magazines) {
        final magazineId =
            magazine['id'] as String;

        final issues = await widget
            .supabaseService
            .getMagazineIssues(magazineId);

        for (final issue in issues) {
          if (saved.contains(issue.id)) {
            allIssues.add(issue);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        favoriteIds = saved;
        favoriteBooks = booksResult;
        favoriteIssues = allIssues;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        favoriteIds = {};
        favoriteBooks = [];
        favoriteIssues = [];
        loading = false;
      });
    }
  }

  Future<void> _removeFavorite(String id) async {
    try {
      await _favoritesService.removeFavorite(id);

      if (!mounted) return;

      setState(() {
        favoriteIds.remove(id);

        favoriteBooks.removeWhere(
          (book) => book.id == id,
        );

        favoriteIssues.removeWhere(
          (issue) => issue.id == id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إزالة العنصر من المفضلة',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إزالة العنصر من المفضلة.',
          ),
        ),
      );
    }
  }

  Future<void> _openBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          book: book,
        ),
      ),
    );

    await _loadFavorites();
  }

  Future<void> _openIssue(
    MagazineIssue issue,
  ) async {
    final book = Book(
      id: issue.id,
      title: issue.title ??
          'العدد ${issue.issueNumber}',
      author: 'مجلة',
      description: issue.description,
      category: 'مجلات',
      coverUrl: issue.coverUrl,
      downloadUrl: issue.downloadUrl,
      isMagazine: true,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DownloadOptionsScreen(
          book: book,
        ),
      ),
    );

    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: orange,
          ),
        ),
      );
    }

    final hasFavorites =
        favoriteBooks.isNotEmpty ||
        favoriteIssues.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المفضلة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: !hasFavorites
            ? _buildEmptyState()
            : RefreshIndicator(
                color: orange,
                onRefresh: _loadFavorites,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (favoriteBooks.isNotEmpty) ...[
                      const Text(
                        'الكتب',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...favoriteBooks.map(
                        (book) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _FavoriteBookCard(
                            book: book,
                            onTap: () =>
                                _openBook(book),
                            onRemove: () =>
                                _removeFavorite(
                              book.id,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (favoriteIssues.isNotEmpty) ...[
                      const SizedBox(height: 12),

                      const Text(
                        'أعداد المجلات',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...favoriteIssues.map(
                        (issue) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _FavoriteIssueCard(
                            issue: issue,
                            onTap: () =>
                                _openIssue(issue),
                            onRemove: () =>
                                _removeFavorite(
                              issue.id,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'أضف الكتب والأعداد التي تعجبك إلى المفضلة\n'
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

// ============================================================
// بطاقة الكتاب
// ============================================================

class _FavoriteBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteBookCard({
    required this.book,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseFavoriteCard(
      coverUrl: book.coverUrl,
      title: book.title,
      subtitle: book.author,
      label: book.category,
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}

// ============================================================
// بطاقة العدد
// ============================================================

class _FavoriteIssueCard extends StatelessWidget {
  final MagazineIssue issue;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteIssueCard({
    required this.issue,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseFavoriteCard(
      coverUrl: issue.coverUrl,
      title: issue.title ??
          'العدد ${issue.issueNumber}',
      subtitle:
          'العدد ${issue.issueNumber}',
      label: 'عدد مجلة',
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}

// ============================================================
// البطاقة المشتركة
// ============================================================

class _BaseFavoriteCard extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BaseFavoriteCard({
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  static const orange = Color(0xFFF28C28);

  @override
  Widget build(BuildContext context) {
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
              SizedBox(
                width: 65,
                height: 88,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: coverUrl != null &&
                          coverUrl!.trim().isNotEmpty
                      ? Image.network(
                          coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const _FavoritePlaceholder(),
                        )
                      : const _FavoritePlaceholder(),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
                        label,
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

class _FavoritePlaceholder extends StatelessWidget {
  const _FavoritePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F3F3),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFFF28C28),
      ),
    );
  }
}
