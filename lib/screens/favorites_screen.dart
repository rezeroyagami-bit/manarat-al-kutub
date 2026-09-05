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

  const FavoritesScreen({super.key, required this.books, required this.supabaseService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  Set<String> favoriteIds = {};
  List<Book> favoriteBooks = [];
  List<MagazineIssue> favoriteIssues = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (mounted) setState(() => loading = true);
    try {
      final saved = await _favoritesService.getFavorites();
      final booksResult = widget.books.where((book) => saved.contains(book.id)).toList();
      final allIssues = <MagazineIssue>[];
      final magazines = await widget.supabaseService.getMagazines();
      for (final magazine in magazines) {
        final id = magazine['id'] as String;
        final issues = await widget.supabaseService.getMagazineIssues(id);
        allIssues.addAll(issues.where((issue) => saved.contains(issue.id)));
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
        favoriteBooks.removeWhere((book) => book.id == id);
        favoriteIssues.removeWhere((issue) => issue.id == id);
      });
    } catch (_) {}
  }

  Future<void> _openBook(Book book) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(book: book)));
    await _loadFavorites();
  }

  Future<void> _openIssue(MagazineIssue issue) async {
    final book = Book(
      id: issue.id,
      title: issue.title ?? 'العدد ${issue.issueNumber}',
      author: 'مجلة',
      description: issue.description,
      category: 'مجلات',
      coverUrl: issue.coverUrl,
      downloadUrl: issue.downloadUrl,
      isMagazine: true,
    );
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DownloadOptionsScreen(book: book)));
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    if (loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: accent)));
    final hasFavorites = favoriteBooks.isNotEmpty || favoriteIssues.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المفضلة', style: TextStyle(fontWeight: FontWeight.bold))),
        body: !hasFavorites
            ? _buildEmptyState(accent)
            : RefreshIndicator(
                color: accent,
                onRefresh: _loadFavorites,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (favoriteBooks.isNotEmpty) ...[
                      const Text('الكتب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...favoriteBooks.map((book) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FavoriteCard(
                              coverUrl: book.coverUrl,
                              title: book.title,
                              subtitle: book.author,
                              label: book.category,
                              accent: accent,
                              onTap: () => _openBook(book),
                              onRemove: () => _removeFavorite(book.id),
                            ),
                          )),
                    ],
                    if (favoriteIssues.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('أعداد المجلات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...favoriteIssues.map((issue) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FavoriteCard(
                              coverUrl: issue.coverUrl,
                              title: issue.title ?? 'العدد ${issue.issueNumber}',
                              subtitle: 'العدد ${issue.issueNumber}',
                              label: 'عدد مجلة',
                              accent: accent,
                              onTap: () => _openIssue(issue),
                              onRemove: () => _removeFavorite(issue.id),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.favorite_border_rounded, size: 48, color: accent),
            ),
            const SizedBox(height: 20),
            const Text('المفضلة فارغة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'أضف الكتب والأعداد التي تعجبك إلى المفضلة\nلتجدها هنا بسهولة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String subtitle;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.accent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
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
                  borderRadius: BorderRadius.circular(10),
                  child: coverUrl != null && coverUrl!.trim().isNotEmpty
                      ? Image.network(coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Placeholder(accent: accent))
                      : _Placeholder(accent: accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Text(label, style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onRemove, tooltip: 'إزالة من المفضلة', icon: const Icon(Icons.favorite_rounded, color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color accent;
  const _Placeholder({required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        color: accent.withValues(alpha: 0.08),
        child: Icon(Icons.menu_book_rounded, color: accent),
      );
}
