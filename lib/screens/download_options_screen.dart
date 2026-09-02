import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';

class DownloadOptionsScreen extends StatelessWidget {
  final Book book;

  const DownloadOptionsScreen({
    super.key,
    required this.book,
  });

  Future<void> openDownloadLink() async {
    final uri = Uri.parse(book.downloadUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خيارات التحميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.download,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                font
