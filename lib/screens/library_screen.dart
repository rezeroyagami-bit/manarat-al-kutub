import 'package:flutter/material.dart';
import '../models/book.dart';
import 'details_screen.dart';

class LibraryScreen extends StatelessWidget {
  final List<Book> books;

  const LibraryScreen({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة'),
      ),
      body: books.isEmpty
          ? const Center(
              child: Text('لا توجد كتب في المكتبة حاليًا'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: SizedBox(
                      width: 55,
                      height: 75,
                      child: book.coverUrl != null &&
                              book.coverUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                book.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.menu_book),
                              ),
                            )
                          : const Icon(
                              Icons.menu_book,
                              size: 40,
                            ),
                    ),
                    title: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(book.author),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(book: book),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
