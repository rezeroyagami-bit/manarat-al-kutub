import 'dart:io';

import 'package:docx_viewer/docx_viewer.dart';
import 'package:flutter/material.dart';
import 'package:koni_archive/io.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class InternalReaderScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const InternalReaderScreen({super.key, required this.filePath, required this.title});

  String get _extension {
    final value = filePath.toLowerCase();
    final dot = value.lastIndexOf('.');
    return dot == -1 ? '' : value.substring(dot + 1);
  }

  @override
  Widget build(BuildContext context) {
    switch (_extension) {
      case 'pdf':
        return _ReaderScaffold(title: title, child: SfPdfViewer.file(File(filePath)));
      case 'doc':
      case 'docx':
        return _ReaderScaffold(
          title: title,
          child: DocxView(
            filePath: filePath,
            fontSize: 18,
            onError: (error) => _ReaderError(message: 'تعذر عرض ملف Word داخل التطبيق.\n$error'),
          ),
        );
      case 'cbr':
        return _CbrReader(filePath: filePath, title: title);
      default:
        return _ReaderScaffold(
          title: title,
          child: const _ReaderError(message: 'هذه الصيغة غير مدعومة حاليًا داخل قارئ KITARA.'),
        );
    }
  }
}

class _ReaderScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReaderScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: child,
    );
  }
}

class _ReaderError extends StatelessWidget {
  final String message;

  const _ReaderError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 17, height: 1.7),
        ),
      ),
    );
  }
}

class _CbrReader extends StatefulWidget {
  final String filePath;
  final String title;

  const _CbrReader({required this.filePath, required this.title});

  @override
  State<_CbrReader> createState() => _CbrReaderState();
}

class _CbrReaderState extends State<_CbrReader> {
  final PageController _pageController = PageController();
  List<String> _pages = [];
  Archive? _archive;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final archive = await openArchiveFile(widget.filePath);
      final pages = archive.files
          .where((entry) {
            final path = entry.path.toLowerCase();
            return path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.webp') || path.endsWith('.gif');
          })
          .map((entry) => entry.path)
          .toList();
      pages.sort(_naturalCompare);
      if (pages.isEmpty) {
        await archive.close();
        throw Exception('لم يتم العثور على صفحات صور داخل ملف CBR.');
      }
      if (!mounted) {
        await archive.close();
        return;
      }
      setState(() {
        _archive = archive;
        _pages = pages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _naturalCompare(String a, String b) {
    final aa = a.toLowerCase().split(RegExp(r'(\d+)'));
    final bb = b.toLowerCase().split(RegExp(r'(\d+)'));
    for (var i = 0; i < aa.length && i < bb.length; i++) {
      final an = int.tryParse(aa[i]);
      final bn = int.tryParse(bb[i]);
      if (an != null && bn != null && an != bn) return an.compareTo(bn);
      final cmp = aa[i].compareTo(bb[i]);
      if (cmp != 0) return cmp;
    }
    return a.compareTo(b);
  }

  Future<List<int>> _readPage(String path) async {
    final archive = _archive;
    if (archive == null) throw Exception('تعذر فتح المجلة.');
    final entry = archive.entry(path);
    if (entry == null) throw Exception('تعذر قراءة الصفحة.');
    return archive.readBytes(entry, maxSize: 50 << 20);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _archive?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: _ReaderError(message: 'تعذر فتح المجلة.\n$_error'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Center(child: Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: Text('${_currentPage + 1}/${_pages.length}'))),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) => FutureBuilder<List<int>>(
          future: _readPage(_pages[index]),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data == null) return const _ReaderError(message: 'تعذر عرض هذه الصفحة.');
            return InteractiveViewer(
              minScale: 0.7,
              maxScale: 4,
              child: Center(child: Image.memory(snapshot.data!, fit: BoxFit.contain, filterQuality: FilterQuality.high)),
            );
          },
        ),
      ),
    );
  }
}
