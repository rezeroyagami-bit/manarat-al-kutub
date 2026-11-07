import 'dart:io';
import 'dart:typed_data';

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
        return _PdfReader(filePath: filePath, title: title);
      case 'doc':
      case 'docx':
        return _ReaderScaffold(title: title, child: DocxView(filePath: filePath, fontSize: 18, onError: (error) => _ReaderError(message: 'تعذر عرض ملف Word داخل التطبيق.\n$error')));
      case 'cbr':
        return _CbrReader(filePath: filePath, title: title);
      default:
        return _ReaderScaffold(title: title, child: const _ReaderError(message: 'هذه الصيغة غير مدعومة حاليًا داخل قارئ KITARA.'));
    }
  }
}

class _ReaderScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _ReaderScaffold({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)), body: child);
}

class _ReaderError extends StatelessWidget {
  final String message;
  const _ReaderError({required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(message, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 17, height: 1.7))));
}

class _PdfReader extends StatefulWidget {
  final String filePath;
  final String title;
  const _PdfReader({required this.filePath, required this.title});
  @override
  State<_PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<_PdfReader> {
  static const double _minZoom = 1.0;
  static const double _maxZoom = 8.0;
  final PdfViewerController _controller = PdfViewerController();
  double _zoom = 1.0;

  void _changeZoom(double delta) {
    final next = (_controller.zoomLevel + delta).clamp(_minZoom, _maxZoom).toDouble();
    _controller.zoomLevel = next;
    setState(() => _zoom = next);
  }

  void _resetZoom() {
    _controller.zoomLevel = _minZoom;
    setState(() => _zoom = _minZoom);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'تصغير', onPressed: _zoom > _minZoom ? () => _changeZoom(-0.5) : null, icon: const Icon(Icons.zoom_out_rounded)),
          Center(child: Text((_zoom * 100).round().toString() + '%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          IconButton(tooltip: 'تكبير', onPressed: _zoom < _maxZoom ? () => _changeZoom(0.5) : null, icon: const Icon(Icons.zoom_in_rounded)),
          IconButton(tooltip: 'ملاءمة الصفحة', onPressed: _resetZoom, icon: const Icon(Icons.fit_screen_rounded)),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.filePath),
        controller: _controller,
        maxZoomLevel: _maxZoom,
        enableDoubleTapZooming: true,
        onZoomLevelChanged: (details) {
          if (!mounted) return;
          setState(() => _zoom = details.newZoomLevel.clamp(_minZoom, _maxZoom).toDouble());
        },
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
  bool _pageZoomed = false;

  @override
  void initState() { super.initState(); _loadPages(); }

  Future<void> _loadPages() async {
    try {
      final archive = await openArchiveFile(widget.filePath);
      final pages = archive.files.where((entry) {
        final path = entry.path.toLowerCase();
        return path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.webp') || path.endsWith('.gif');
      }).map((entry) => entry.path).toList();
      pages.sort(_naturalCompare);
      if (pages.isEmpty) { await archive.close(); throw Exception('لم يتم العثور على صفحات صور داخل ملف CBR.'); }
      if (!mounted) { await archive.close(); return; }
      setState(() { _archive = archive; _pages = pages; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
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

  Future<Uint8List> _readPage(String path) async {
    final archive = _archive;
    if (archive == null) throw Exception('تعذر فتح المجلة.');
    final entry = archive.entry(path);
    if (entry == null) throw Exception('تعذر قراءة الصفحة.');
    final bytes = await archive.readBytes(entry, maxSize: 50 << 20);
    return Uint8List.fromList(bytes);
  }

  void _onZoomChanged(bool zoomed) {
    if (_pageZoomed == zoomed || !mounted) return;
    setState(() => _pageZoomed = zoomed);
  }

  @override
  void dispose() { _pageController.dispose(); _archive?.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)), body: _ReaderError(message: 'تعذر فتح المجلة.\n$_error'));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Center(child: Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: Text((_currentPage + 1).toString() + '/' + _pages.length.toString()))),
          IconButton(
            tooltip: 'طريقة التكبير',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كبّر الصفحة بإصبعين، ثم اسحبها للتحرك. انقر مرتين للعودة للحجم الطبيعي.'))),
            icon: const Icon(Icons.pinch_rounded),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _pageZoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        itemCount: _pages.length,
        onPageChanged: (index) => setState(() { _currentPage = index; _pageZoomed = false; }),
        itemBuilder: (context, index) => FutureBuilder<Uint8List>(
          future: _readPage(_pages[index]),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data == null) return const _ReaderError(message: 'تعذر عرض هذه الصفحة.');
            return _CbrPage(key: ValueKey(_pages[index]), bytes: snapshot.data!, onZoomChanged: _onZoomChanged);
          },
        ),
      ),
    );
  }
}

class _CbrPage extends StatefulWidget {
  final Uint8List bytes;
  final ValueChanged<bool> onZoomChanged;
  const _CbrPage({super.key, required this.bytes, required this.onZoomChanged});
  @override
  State<_CbrPage> createState() => _CbrPageState();
}

class _CbrPageState extends State<_CbrPage> {
  final TransformationController _transformController = TransformationController();
  Offset? _doubleTapPosition;
  bool _zoomed = false;

  void _handleDoubleTap() {
    if (_zoomed) {
      _transformController.value = Matrix4.identity();
      _zoomed = false;
      widget.onZoomChanged(false);
      return;
    }
    const scale = 2.5;
    final point = _doubleTapPosition ?? Offset.zero;
    _transformController.value = Matrix4.identity()
      ..translate(point.dx * (1 - scale), point.dy * (1 - scale))
      ..scale(scale);
    _zoomed = true;
    widget.onZoomChanged(true);
  }

  @override
  void dispose() { _transformController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 1.0,
          maxScale: 8.0,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(160),
          clipBehavior: Clip.hardEdge,
          constrained: true,
          onInteractionUpdate: (_) {
            final zoomed = _transformController.value.getMaxScaleOnAxis() > 1.01;
            if (_zoomed != zoomed) {
              _zoomed = zoomed;
              widget.onZoomChanged(zoomed);
            }
          },
          onInteractionEnd: (_) {
            final zoomed = _transformController.value.getMaxScaleOnAxis() > 1.01;
            _zoomed = zoomed;
            widget.onZoomChanged(zoomed);
          },
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Image.memory(widget.bytes, fit: BoxFit.contain, filterQuality: FilterQuality.high),
          ),
        ),
      ),
    );
  }
}
