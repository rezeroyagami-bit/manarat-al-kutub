import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/magazine_issue.dart';
import '../services/favorites_service.dart';
import '../services/supabase_service.dart';
import 'download_options_screen.dart';

class MagazineScreen extends StatefulWidget {
  final String magazineId;
  final String magazineName;
  final String? description;
  final String? coverUrl;

  const MagazineScreen({
    super.key,
    required this.magazineId,
    required this.magazineName,
    this.description,
    this.coverUrl,
  });

  @override
  State<MagazineScreen> createState() => _MagazineScreenState();
}

class _MagazineScreenState extends State<MagazineScreen> {
  final SupabaseService _service = SupabaseService();
  final FavoritesService _favoritesService = FavoritesService();
  List<MagazineIssue> issues = [];
  Set<String> favoriteIds = {};
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _loadFavorites();
  }

  Future<void> _loadIssues() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final result = await _service.getMagazineIssues(widget.magazineId);
      if (!mounted) return;
      setState(() {
        issues = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'تعذر تحميل أعداد المجلة.\nتحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final saved = await _favoritesService.getFavorites();
      if (!mounted) return;
      setState(() => favoriteIds = saved);
    } catch (_) {}
  }

  Future<void> _toggleFavorite(MagazineIssue issue) async {
    try {
      await _favoritesService.toggleFavorite(issue.id);
      if (!mounted) return;
      setState(() {
        if (favoriteIds.contains(issue.id)) {
          favoriteIds.remove(issue.id);
        } else {
          favoriteIds.add(issue.id);
        }
      });
    } catch (_) {}
  }

  void _openIssue(MagazineIssue issue) {
    final book = Book(
      id: issue.id,
      title: issue.title ?? 'العدد ${issue.issueNumber}',
      author: widget.magazineName,
      description: issue.description,
      category: 'مجلات',
      coverUrl: issue.coverUrl,
      downloadUrl: issue.downloadUrl,
      isMagazine: true,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DownloadOptionsScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.magazineName, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: RefreshIndicator(
          color: accent,
          onRefresh: () async {
            await _loadIssues();
            await _loadFavorites();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: widget.coverUrl != null && widget.coverUrl!.trim().isNotEmpty
                              ? Image.network(
                                  widget.coverUrl!,
                                  height: 320,
                                  width: 230,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _CoverPlaceholder(accent: accent, height: 320),
                                )
                              : _CoverPlaceholder(accent: accent, height: 320),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(widget.magazineName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                      if (widget.description != null && widget.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(widget.description!, textAlign: TextAlign.right, style: TextStyle(fontSize: 16, height: 1.8, color: isDark ? Colors.white70 : Colors.black54)),
                      ],
                      const SizedBox(height: 30),
                      const Text('الأعداد', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (loading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: accent)),
                )
              else if (errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: errorMessage!, onRetry: _loadIssues, accent: accent),
                )
              else if (issues.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('لا توجد أعداد مضافة حاليًا.', style: TextStyle(fontSize: 17, color: Colors.grey))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final issue = issues[index];
                        return _IssueCard(
                          issue: issue,
                          isFavorite: favoriteIds.contains(issue.id),
                          accent: accent,
                          onFavorite: () => _toggleFavorite(issue),
                          onTap: () => _openIssue(issue),
                        );
                      },
                      childCount: issues.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 22,
                      childAspectRatio: 0.58,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final MagazineIssue issue;
  final bool isFavorite;
  final Color accent;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _IssueCard({
    required this.issue,
    required this.isFavorite,
    required this.accent,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: issue.coverUrl != null && issue.coverUrl!.trim().isNotEmpty
                        ? Image.network(issue.coverUrl!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _CoverPlaceholder(accent: accent))
                        : _CoverPlaceholder(accent: accent),
                  ),
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 22,
                        color: isFavorite ? Colors.red : accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'العدد ${issue.issueNumber}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent),
        ),
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final Color accent;
  final double height;
  const _CoverPlaceholder({required this.accent, this.height = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Center(child: Icon(Icons.menu_book_rounded, size: 45, color: accent)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final Color accent;
  const _ErrorState({required this.message, required this.onRetry, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 55, color: accent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
