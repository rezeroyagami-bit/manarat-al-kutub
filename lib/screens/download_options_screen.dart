import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../models/book.dart';
import '../services/ad_block_detector.dart';
import '../services/coins_service.dart';
import '../services/downloads_service.dart';

class DownloadOptionsScreen extends StatefulWidget {
  final Book book;
  const DownloadOptionsScreen({super.key, required this.book});
  @override
  State<DownloadOptionsScreen> createState() => _DownloadOptionsScreenState();
}

class _DownloadOptionsScreenState extends State<DownloadOptionsScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  bool _earnedReward = false;
  double _progress = 0.0;
  String _status = '';

  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _proxyBaseUrl = 'https://kitara-download-proxy.vercel.app';
  final Dio _dio = Dio();
  final PublicFileSaver _fileSaver = PublicFileSaver();
  final DownloadsService _downloadsService = DownloadsService();

  @override
  void initState() { super.initState(); _prepareRewardedAd(); }

  Future<void> _prepareRewardedAd() async {
    try { await MobileAds.instance.initialize(); } catch (e) { debugPrint('AdMob initialization error: $e'); }
    if (!mounted) return;
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (_isLoadingAd || _rewardedAd != null) return;
    _isLoadingAd = true;
    if (mounted) setState(() {});
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad; _isLoadingAd = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose(); _rewardedAd = null;
              if (_earnedReward) { _earnedReward = false; _startDownload(); } else { _loadRewardedAd(); }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose(); _rewardedAd = null; _earnedReward = false; _loadRewardedAd();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل الإعلان. حاول مرة أخرى.')));
            },
          );
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null; _isLoadingAd = false;
          debugPrint('REWARDED AD LOAD ERROR: ${error.code} ${error.message}');
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    if (_isDownloading) return;
    final blocked = await AdBlockDetector.isLikelyBlocked();
    if (blocked) { _showAdBlockMessage(); return; }
    if (_rewardedAd == null) {
      if (mounted) setState(() => _status = 'جاري تجهيز الإعلان...');
      _loadRewardedAd();
      for (var i = 0; i < 20; i++) {
        if (_rewardedAd != null || !mounted) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted) return;
      if (_rewardedAd == null) {
        setState(() => _status = '');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 5), content: Text('الإعلان لم يجهز بعد. تحقق من الإنترنت وحاول مرة أخرى.')));
        _loadRewardedAd();
        return;
      }
      setState(() => _status = '');
    }
    final ad = _rewardedAd;
    if (ad == null) return;
    _rewardedAd = null; _earnedReward = false;
    ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) { _earnedReward = true; });
  }

  void _showAdBlockMessage() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم اكتشاف مانع الإعلانات'),
        content: const Text('لا يمكن تحميل الملفات أثناء استخدام مانع الإعلانات.\n\nللمواصلة، يرجى تعطيل مانع الإعلانات ثم إعادة المحاولة.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('حسنًا'))],
      ),
    );
  }

  String _sanitizeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'''[\\/:*?"<>|]'''), '_').trim();
    return cleaned.isEmpty ? 'kitara_file' : cleaned;
  }

  Future<List<int>> _readHeader(File file) async {
    final bytes = <int>[];
    await for (final chunk in file.openRead(0, 16)) { bytes.addAll(chunk); if (bytes.length >= 16) break; }
    return bytes;
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) { if (bytes[i] != signature[i]) return false; }
    return true;
  }
  bool _isRar(List<int> header) => _startsWith(header, [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07]);
  bool _isOldMicrosoftOffice(List<int> header) => _startsWith(header, [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]);

  bool _isValidBookFile(String contentType, List<int> header) {
    final type = contentType.toLowerCase();
    if (type.contains('text/html') || type.contains('application/json') || type.startsWith('text/')) return false;
    return _startsWith(header, [0x25, 0x50, 0x44, 0x46]) || _startsWith(header, [0x50, 0x4B, 0x03, 0x04]) || _startsWith(header, [0x50, 0x4B, 0x05, 0x06]) || _startsWith(header, [0x50, 0x4B, 0x07, 0x08]) || _isRar(header) || _isOldMicrosoftOffice(header);
  }

  String _extensionFromContentType(String contentType, List<int> header) {
    final type = contentType.toLowerCase();
    if (type.contains('wordprocessingml.document')) return '.docx';
    if (type.contains('application/msword')) return '.doc';
    if (type.contains('pdf') || _startsWith(header, [0x25, 0x50, 0x44, 0x46])) return '.pdf';
    if (type.contains('epub')) return '.epub';
    if (type.contains('comicbook+zip')) return '.cbz';
    if (type.contains('zip') || _startsWith(header, [0x50, 0x4B, 0x03, 0x04])) return '.zip';
    if (type.contains('rar') || type.contains('comicbook') || _isRar(header)) return widget.book.isMagazine ? '.cbr' : '.rar';
    if (_isOldMicrosoftOffice(header)) return '.doc';
    return '';
  }

  String _downloadFileName(String contentType, List<int> header) {
    final title = _sanitizeFileName(widget.book.title);
    final extension = _extensionFromContentType(contentType, header);
    if (extension.isEmpty || title.toLowerCase().endsWith(extension)) return title;
    return '$title$extension';
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
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

  String _friendlyProxyError(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) { final message = data['error']; if (message is String && message.isNotEmpty) return message; }
    return 'تعذر الحصول على الملف من الخادم. حاول مرة أخرى.';
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    if (mounted) setState(() { _isDownloading = true; _downloadCompleted = false; _progress = 0.0; _status = 'جاري تجهيز التحميل...'; });
    File? temporaryFile;
    try {
      final proxyUrl = '$_proxyBaseUrl/download/${Uri.encodeComponent(widget.book.id)}';
      final temporaryDirectory = await getTemporaryDirectory();
      final temporaryPath = '${temporaryDirectory.path}/kitara_download.tmp';
      temporaryFile = File(temporaryPath);
      if (await temporaryFile.exists()) await temporaryFile.delete();
      if (mounted) setState(() => _status = 'جاري تنزيل الملف...');
      final response = await _dio.download(proxyUrl, temporaryPath, deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (!mounted) return; final value = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          setState(() { _progress = value; _status = total > 0 ? 'جاري التحميل... ${(value * 100).toInt()}%' : 'جاري التحميل...'; });
        },
        options: Options(responseType: ResponseType.bytes, followRedirects: true, maxRedirects: 10, receiveTimeout: const Duration(minutes: 15), sendTimeout: const Duration(minutes: 2), headers: const {'Accept': '*/*'}, validateStatus: (status) => status != null && status >= 200 && status < 400));
      if (!await temporaryFile.exists()) throw Exception('TEMP_FILE_NOT_FOUND');
      final fileLength = await temporaryFile.length();
      final contentType = response.headers.value('content-type') ?? '';
      final header = await _readHeader(temporaryFile);
      if (fileLength < 1024 || !_isValidBookFile(contentType, header)) throw Exception(_friendlyProxyError(response));

      final fileName = _downloadFileName(contentType, header);
      final finalPath = '${temporaryDirectory.path}/$fileName';
      if (finalPath != temporaryFile.path) temporaryFile = await temporaryFile.rename(finalPath);
      if (mounted) setState(() => _status = 'جاري حفظ الملف في التنزيلات...');
      final savedFile = await _fileSaver.saveFile(file: temporaryFile, fileName: fileName, mimeType: _getMimeType(fileName));
      if (savedFile == null || !savedFile.isSuccess) throw Exception('PUBLIC_SAVE_FAILED');
      await _downloadsService.copyToAppDownloads(source: temporaryFile, book: widget.book, fileName: fileName);
      final newCoinBalance = await CoinsService().awardDownloadCoin();
      try { await temporaryFile.delete(); } catch (_) {}
      if (mounted) {
        setState(() { _progress = 1.0; _isDownloading = false; _downloadCompleted = true; _status = 'اكتمل التحميل'; });
        final coinText = newCoinBalance == null ? 'تم تحميل الملف وإضافته إلى «تنزيلاتي» في KITARA.' : 'تم التحميل بنجاح. حصلت على كوين واحد. رصيدك: $newCoinBalance';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(coinText)));
      }
      _loadRewardedAd();
    } on DioException catch (e) {
      await _cleanupTemporaryFile(temporaryFile); if (!mounted) return;
      final message = e.response?.statusCode != null && e.response?.data != null ? _friendlyProxyError(e.response) : 'تعذر الاتصال بخادم التحميل. تحقق من الإنترنت وحاول مرة أخرى.';
      setState(() { _isDownloading = false; _progress = 0.0; _status = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 8), content: Text('خطأ التحميل:\n$message'))); _loadRewardedAd();
    } catch (e, stackTrace) {
      debugPrint('DOWNLOAD ERROR: $e'); debugPrint('DOWNLOAD STACK TRACE:\n$stackTrace'); await _cleanupTemporaryFile(temporaryFile); if (!mounted) return;
      setState(() { _isDownloading = false; _progress = 0.0; _status = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 10), content: Text('خطأ التحميل:\n${e.toString().replaceFirst('Exception: ', '')}'))); _loadRewardedAd();
    }
  }

  Future<void> _cleanupTemporaryFile(File? file) async { if (file == null) return; try { if (await file.exists()) await file.delete(); } catch (e) { debugPrint('CLEANUP ERROR: $e'); } }
  void _startFreeDownload() { if (!_isDownloading) _showRewardedAd(); }
  @override void dispose() { _rewardedAd?.dispose(); _dio.close(force: true); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Scaffold(appBar: AppBar(title: const Text('التحميل')), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 30), const Icon(Icons.download_rounded, size: 80, color: orange), const SizedBox(height: 20),
      Text(widget.book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 35),
      if (!_isDownloading && !_downloadCompleted) ElevatedButton.icon(onPressed: _startFreeDownload, icon: _isLoadingAd ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download_rounded), label: Text(_isLoadingAd ? 'جاري تجهيز الإعلان...' : 'بدء التحميل'), style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(55))),
      if (_isDownloading || _downloadCompleted) ...[const SizedBox(height: 10), Text(_status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _downloadCompleted ? Colors.green : null)), const SizedBox(height: 20), LinearProgressIndicator(value: _progress, minHeight: 10, borderRadius: BorderRadius.circular(10)), if (_downloadCompleted) ...[const SizedBox(height: 25), OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.check_circle_outline), label: const Text('العودة'))]],
    ])));
  }
}
