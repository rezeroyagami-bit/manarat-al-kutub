import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../models/book.dart';
import '../services/downloads_service.dart';

class DownloadOptionsScreen extends StatefulWidget {
  final Book book;

  const DownloadOptionsScreen({super.key, required this.book});

  @override
  State<DownloadOptionsScreen> createState() => _DownloadOptionsScreenState();
}

class _DownloadOptionsScreenState extends State<DownloadOptionsScreen> {
  final Dio _dio = Dio();
  final PublicFileSaver _fileSaver = PublicFileSaver();
  final DownloadsService _downloadsService = DownloadsService();

  bool _downloading = false;
  String _status = '';

  String _sanitizeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'kitara_download' : cleaned;
  }

  String? _fileNameFromContentDisposition(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final encoded = RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(value)?.group(1);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = Uri.decodeComponent(encoded).trim().replaceAll('"', '');
        if (decoded.isNotEmpty) return _sanitizeFileName(decoded);
      } catch (_) {}
    }

    final quoted = RegExp(r'filename\\s*=\\s*"([^"]+)"', caseSensitive: false).firstMatch(value)?.group(1);
    if (quoted != null && quoted.isNotEmpty) return _sanitizeFileName(quoted.trim());

    final plain = RegExp(r'filename\\s*=\\s*([^;]+)', caseSensitive: false).firstMatch(value)?.group(1);
    if (plain != null && plain.isNotEmpty) return _sanitizeFileName(plain.trim().replaceAll('"', ''));

    return null;
  }

  Future<List<int>> _readHeader(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(16);
    } finally {
      await raf.close();
    }
  }

  bool _startsWith(List<int> data, List<int> signature) {
    if (data.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (data[i] != signature[i]) return false;
    }
    return true;
  }

  bool _isValidBookFile(String contentType, List<int> header) {
    final type = contentType.toLowerCase();
    if (type.contains('text/html') || type.contains('application/json') || type.startsWith('text/')) return false;
    if (_startsWith(header, [0x25, 0x50, 0x44, 0x46])) return true;
    if (_startsWith(header, [0x50, 0x4b, 0x03, 0x04])) return true;
    if (_startsWith(header, [0x52, 0x61, 0x72, 0x21])) return true;
    return type.contains('pdf') || type.contains('zip') || type.contains('rar') || type.contains('epub') || type.contains('comicbook');
  }

  String _extensionFromContentType(String contentType, List<int> header) {
    final type = contentType.toLowerCase();
    if (type.contains('pdf') || _startsWith(header, [0x25, 0x50, 0x44, 0x46])) return '.pdf';
    if (type.contains('epub')) return '.epub';
    if (type.contains('zip') || _startsWith(header, [0x50, 0x4b, 0x03, 0x04])) return '.zip';
    if (type.contains('rar') || type.contains('comicbook') || _startsWith(header, [0x52, 0x61, 0x72, 0x21])) return '.rar';
    return '';
  }

  String _fallbackFileName(String contentType, List<int> header) {
    final extension = _extensionFromContentType(contentType, header);
    return '${_sanitizeFileName(widget.book.title)}$extension';
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.cbr')) return 'application/vnd.comicbook-rar';
    if (lower.endsWith('.cbz')) return 'application/vnd.comicbook+zip';
    if (lower.endsWith('.epub')) return 'application/epub+zip';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.rar')) return 'application/vnd.rar';
    return 'application/octet-stream';
  }

  String _friendlyProxyError(Response response) {
    final status = response.statusCode;
    if (status != null && status >= 400) return 'تعذر تحميل الملف (خطأ $status).';
    return 'الملف الذي وصل ليس ملف كتاب صالحًا.';
  }

  Future<void> _startDownload() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _status = 'جاري التحضير للتحميل...';
    });

    File? temporaryFile;
    try {
      final temporaryDirectory = await getTemporaryDirectory();
      temporaryFile = File('${temporaryDirectory.path}/kitara_download.tmp');
      if (await temporaryFile.exists()) await temporaryFile.delete();

      final response = await _dio.download(
        widget.book.downloadUrl,
        temporaryFile.path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout: const Duration(minutes: 15),
          sendTimeout: const Duration(minutes: 2),
          headers: const {'Accept': '*/*'},
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );

      if (!await temporaryFile.exists()) throw Exception('TEMP_FILE_NOT_FOUND');
      final fileLength = await temporaryFile.length();
      final contentType = response.headers.value('content-type') ?? '';
      final contentDisposition = response.headers.value('content-disposition');
      final header = await _readHeader(temporaryFile);

      if (fileLength < 1024 || !_isValidBookFile(contentType, header)) {
        throw Exception(_friendlyProxyError(response));
      }

      final fileName = _fileNameFromContentDisposition(contentDisposition) ?? _fallbackFileName(contentType, header);
      final finalPath = '${temporaryDirectory.path}/$fileName';
      if (finalPath != temporaryFile.path) {
        final renamed = await temporaryFile.rename(finalPath);
        temporaryFile = renamed;
      }

      if (mounted) setState(() => _status = 'جاري حفظ الملف في التنزيلات...');

      final savedFile = await _fileSaver.saveFile(
        file: temporaryFile,
        fileName: fileName,
        mimeType: _getMimeType(fileName),
      );

      if (savedFile == null || !savedFile.isSuccess) {
        throw Exception('SAVE_FAILED');
      }

      await _downloadsService.copyToAppDownloads(
        source: temporaryFile,
        book: widget.book,
        fileName: fileName,
      );

      if (!mounted) return;
      setState(() => _status = 'تم تحميل الملف بنجاح.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملف في التنزيلات وداخل KITARA.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'فشل التحميل.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الملف: $e')),
      );
    } finally {
      if (temporaryFile != null) {
        try {
          if (await temporaryFile.exists()) await temporaryFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحميل الكتاب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloading ? null : _startDownload,
                icon: const Icon(Icons.download),
                label: Text(_downloading ? 'جاري التحميل...' : 'تحميل'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_status, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
