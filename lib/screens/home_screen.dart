import 'package:flutter/material.dart';
import '../models/book.dart';
import 'details_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Book> books;
  final VoidCallback onTheme;

  const HomeScreen({
    super.key,
    required this.books,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KITARA — كيتارا',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: onTheme,
            icon: Icon(
              isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
              color: orange,
            ),
          ),
        ],
      ),
      body: books.isEmpty
          ? const Center(
              child: Text(
                'لا توجد كتب حاليًا',
                style: TextStyle(fontSize: 18),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(book: book),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: book.coverUrl != null &&
                                  book.coverUrl!.isNotEmpty
                              ? Image.network(
                                  book.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(
                                    Icons.menu_book_rounded,
                                    size: 60,
                                  ),
                                )
                              : const Icon(
                                  Icons.menu_book_rounded,
                                  size: 60,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
