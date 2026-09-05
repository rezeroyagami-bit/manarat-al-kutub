import 'dart:io';

import 'package:flutter/material.dart';
import '../services/downloads_service.dart';

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
    await _service.deleteDownload(download);
    await _loadDownloads();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنزيلاتي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [IconButton(onPressed: _loadDownloads, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : _downloads.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_for_offline_outlined, size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد تنزيلات حتى الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('ستظهر الكتب والمجلات التي تنزلها هنا', style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _downloads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _downloads[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: SizedBox(
                            width: 55,
                            height: 72,
                            child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded, size: 38)),
                                  )
                                : const Icon(Icons.menu_book_rounded, size: 40, color: orange),
                          ),
                          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _delete(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
