import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../services/downloads_service.dart';
import 'internal_reader_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadsService _service = DownloadsService();
  List<DownloadedBook> _downloads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DownloadsService.downloadsChanged.addListener(_onDownloadsChanged);
    _loadDownloads();
  }

  @override
  void dispose() {
    DownloadsService.downloadsChanged.removeListener(_onDownloadsChanged);
    super.dispose();
  }

  void _onDownloadsChanged() {
    if (!mounted) return;
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final downloads = await _service.getDownloads();
    if (!mounted) return;
    setState(() {
      _downloads = downloads;
      _loading = false;
    });
  }

  Future<void> _delete(DownloadedBook download) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التنزيل'),
        content: Text(
          'هل تريد حذف «${download.title}» من تنزيلاتك؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteDownload(download);
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.cbr')) return 'application/vnd.comicbook-rar';
    if (lower.endsWith('.cbz')) return 'application/vnd.comicbook+zip';
    if (lower.endsWith('.epub')) return 'application/epub+zip';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.rar')) return 'application/vnd.rar';
    return 'application/octet-stream';
  }

  bool _isInternalFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.cbr');
  }

  Future<void> _openDownload(DownloadedBook download) async {
    final file = File(download.filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الملف لم يعد موجودًا على الجهاز.')));
      await _loadDownloads();
      return;
    }

    if (_isInternalFormat(file.path)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InternalReaderScreen(filePath: file.path, title: download.title),
        ),
      );
      return;
    }

    final result = await OpenFilex.open(file.path, type: _mimeType(file.path));
    if (!mounted || result.type.name == 'done') return;
    final message = result.type.name == 'noAppToOpen'
        ? 'لا يوجد تطبيق على الهاتف لفتح هذا النوع من الملفات.'
        : 'تعذر فتح الملف: ${result.message}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنزيلاتي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _downloads.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_for_offline_outlined, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد تنزيلات حتى الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('ستظهر الكتب والمجلات التي تنزلها هنا', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: accent,
                  onRefresh: _loadDownloads,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _downloads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _downloads[index];
                      return Card(
                        child: ListTile(
                          onTap: () => _openDownload(item),
                          contentPadding: const EdgeInsets.all(10),
                          leading: SizedBox(
                            width: 55,
                            height: 72,
                            child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, size: 38, color: accent),
                                    ),
                                  )
                                : Icon(Icons.menu_book_rounded, size: 40, color: accent),
                          ),
                          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, color: accent),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _delete(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
