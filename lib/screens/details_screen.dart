import 'package:flutter/material.dart';
import '../models/book.dart';
import 'download_options_screen.dart';

class DetailsScreen extends StatelessWidget {
  final Book book;

  const DetailsScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الكتاب'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  book.coverUrl!,
                  height: 360,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 360,
                    child: Icon(
                      Icons.menu_book,
                      size: 100,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(
                height: 360,
                child: Icon(
                  Icons.menu_book,
                  size: 100,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.author,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              book.description ?? 'لا يوجد وصف لهذا الكتاب.',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DownloadOptionsScreen(book: book),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('خيارات التحميل'),
            ),
          ],
        ),
      ),
    );
  }
}
