import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import 'download_options_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Book book;

  const DetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    final favorites =
        prefs.getStringList('favorite_books') ?? [];

    if (!mounted) return;

    setState(() {
      isFavorite = favorites.contains(widget.book.id.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    final favorites =
        prefs.getStringList('favorite_books') ?? [];

    final bookId = widget.book.id.toString();

    if (favorites.contains(bookId)) {
      favorites.remove(bookId);
    } else {
      favorites.add(bookId);
    }

    await prefs.setStringList(
      'favorite_books',
      favorites,
    );

    if (!mounted) return;

    setState(() {
      isFavorite = favorites.contains(bookId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'تمت إضافة الكتاب إلى المفضلة'
              : 'تمت إزالة الكتاب من المفضلة',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الكتاب',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // الغلاف
            if (widget.book.coverUrl != null &&
                widget.book.coverUrl!.isNotEmpty)
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 280,
                    maxHeight: 390,
                  ),

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 16,
                        offset: Offset(0, 7),
                        color: Colors.black26,
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),

                    child: Image.network(
                      widget.book.coverUrl!,
                      fit: BoxFit.contain,

                      errorBuilder:
                          (_, __, ___) =>
                              Container(
                        height: 300,
                        width: 220,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(18),
                          color: orange.withValues(
                            alpha: 0.10,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 90,
                          color: orange,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  width: 220,
                  height: 300,
                  decoration: BoxDecoration(
                    color: orange.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 90,
                    color: orange,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // العنوان
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            // المؤلف
            Text(
              widget.book.author,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            // القسم
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: orange.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  widget.book.category,
                  style: const TextStyle(
                    color: orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // الوصف
            const Text(
              'عن المحتوى',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.book.description ??
                  'لا يوجد وصف لهذا الكتاب.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 28),

            // زر التحميل
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DownloadOptionsScreen(
                        book: widget.book,
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.download_rounded,
                ),

                label: const Text(
                  'خيارات التحميل',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
