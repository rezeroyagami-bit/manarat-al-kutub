import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../models/book.dart';

extension PublicSavedFileNullableX on PublicSavedFile? {
  bool get isSuccess => this != null && (this as PublicSavedFile).isSuccess;
}

class DownloadedBook {
  final String bookId;
  final String title;
  final String author;
  final String? coverUrl;
  final String filePath;
  final DateTime downloadedAt;

  const DownloadedBook({required this.bookId, required this.title, required this.author, required this.coverUrl, required this.filePath, required this.downloadedAt});

  Map<String, dynamic> toMap() => {'book_id': bookId, 'title': title, 'author': author, 'cover_url': coverUrl, 'file_path': filePath, 'downloaded_at': downloadedAt.toIso8601String()};

  factory DownloadedBook.fromMap(Map<String, dynamic> map) => DownloadedBook(
    bookId: map['book_id'] as String? ?? '',
    title: map['title'] as String? ?? 'كتاب',
    author: map['author'] as String? ?? '',
    coverUrl: map['cover_url'] as String?,
    filePath: map['file_path'] as String? ?? '',
    downloadedAt: DateTime.tryParse(map['downloaded_at'] as String? ?? '') ?? DateTime.now(),
  );
}

class DownloadsService {
  static const _prefsKey = 'kitara_downloaded_books';

  // Notifies any open DownloadsScreen immediately when the list changes.
  static final downloadsChanged = ValueNotifier<int>(0);

  Future<Directory> _downloadsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/kitara_downloads');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<List<DownloadedBook>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    final result = <DownloadedBook>[];
    var changed = false;
    for (final item in raw) {
      try {
        final download = DownloadedBook.fromMap(jsonDecode(item) as Map<String, dynamic>);
        if (download.filePath.isNotEmpty && await File(download.filePath).exists()) result.add(download); else changed = true;
      } catch (_) { changed = true; }
    }
    result.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    if (changed) await _save(result);
    return result;
  }

  Future<String> copyToAppDownloads({required File source, required Book book, required String fileName}) async {
    final directory = await _downloadsDirectory();
    final target = File('${directory.path}/$fileName');
    if (await target.exists()) await target.delete();
    final saved = await source.copy(target.path);
    final current = await getDownloads();
    final filtered = current.where((item) => item.bookId != book.id).toList();
    filtered.add(DownloadedBook(bookId: book.id, title: book.title, author: book.author, coverUrl: book.coverUrl, filePath: saved.path, downloadedAt: DateTime.now()));
    filtered.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    await _save(filtered);
    downloadsChanged.value++;
    return saved.path;
  }

  Future<void> deleteDownload(DownloadedBook download) async {
    try { final file = File(download.filePath); if (await file.exists()) await file.delete(); } catch (_) {}
    final current = await getDownloads();
    current.removeWhere((item) => item.filePath == download.filePath);
    await _save(current);
    downloadsChanged.value++;
  }

  Future<void> _save(List<DownloadedBook> downloads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, downloads.map((item) => jsonEncode(item.toMap())).toList());
  }
}
