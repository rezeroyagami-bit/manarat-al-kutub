import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/magazine_issue.dart';
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

  List<MagazineIssue> issues = [];
  bool loading = true;
  String? errorMessage;

  static const orange = Color(0xFFF28C28);

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await _service.getMagazineIssues(
        widget.magazineId,
      );

      if (!mounted) return;

      setState(() {
        issues = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
            'تعذر تحميل أعداد المجلة.\n'
            'تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
      });
    }
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
      MaterialPageRoute(
        builder: (_) => DownloadOptionsScreen(
          book: book,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.magazineName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: orange,
          onRefresh: _loadIssues,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(18),
                          child: widget.coverUrl != null &&
                                  widget.coverUrl!
                                      .trim()
                                      .isNotEmpty
                              ? Image.network(
                                  widget.coverUrl!,
                                  height: 320,
                                  width: 230,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) {
                                    return const _CoverPlaceholder(
                                      height: 320,
                                    );
                                  },
                                )
                              : const _CoverPlaceholder(
                                  height: 320,
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        widget.magazineName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (widget.description != null &&
                          widget.description!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.description!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      const Text(
                        'الأعداد',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: orange,
                    ),
                  ),
                )
              else if (errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: errorMessage!,
                    onRetry: _loadIssues,
                  ),
                )
              else if (issues.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'لا توجد أعداد مضافة حاليًا.',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    30,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final issue = issues[index];

                        return _IssueCard(
                          issue: issue,
                          onTap: () => _openIssue(issue),
                        );
                      },
                      childCount: issues.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
  final VoidCallback onTap;

  const _IssueCard({
    required this.issue,
    required this.onTap,
  });

  static const orange = Color(0xFFF28C28);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: issue.coverUrl != null &&
                      issue.coverUrl!.trim().isNotEmpty
                  ? Image.network(
                      issue.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const _CoverPlaceholder();
                      },
                    )
                  : const _CoverPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'العدد ${issue.issueNumber}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final double height;

  const _CoverPlaceholder({
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 45,
          color: Color(0xFFF28C28),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Color(0xFFF28C28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
