import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  double _progress = 0.0;
  String _status = '';

  static const String _rewardedAdUnitId = 'ca-app-pub-6792981270949925/4708033165';

  final Dio _dio = Dio();
  final PublicFileSaver _fileSaver = PublicFileSaver();
  final DownloadsService _downloadsService = DownloadsService();
  bool _earnedReward = false;
  String _mediaFireCookieHeader = '';
  List<int> _lastHeader = <int>[];

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (_isLoadingAd) return;
    _isLoadingAd = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingAd = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              if (_earnedReward) {
                _earnedReward = false;
                _startDownload();
              } else {
                _loadRewardedAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _earnedReward = false;
              _loadRewardedAd();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تعذر تشغيل الإعلان. حاول مرة أخرى.')),
                );
              }
            },
          );
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingAd = false;
          debugPrint('REWARDED AD LOAD ERROR: ${error.message}');
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isDownloading) return;
    final ad = _rewardedAd;
    if (ad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الإعلان غير جاهز حاليًا. حاول مرة أخرى بعد قليل.')),
      );
      _loadRewardedAd();
      return;
    }
    _rewardedAd = null;
    _earnedReward = false;
    ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      _earnedReward = true;
    });
  }

  Map<String, String> _requestHeaders() {
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'ar-DZ,ar;q=0.9,en-US;q=0.8,en;q=0.7',
      'Cache-Control': 'no-cache',
    };
    if (_mediaFireCookieHeader.isNotEmpty) headers['Cookie'] = _mediaFireCookieHeader;
    return headers;
  }

  void _storeCookies(Headers headers) {
    final setCookies = headers['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return;
    final cookies = <String, String>{};
    if (_mediaFireCookieHeader.isNotEmpty) {
      for (final part in _mediaFireCookieHeader.split(';')) {
        final pieces = part.trim().split('=');
        if (pieces.length >= 2) cookies[pieces.first.trim()] = pieces.sublist(1).join('=').trim();
      }
    }
    for (final raw in setCookies) {
      final first = raw.split(';').first.trim();
      final pieces = first.split('=');
      if (pieces.length >= 2) cookies[pieces.first.trim()] = pieces.sublist(1).join('=').trim();
    }
    _mediaFireCookieHeader = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  String _decodeHtml(String value) => value
      .replaceAll(r'\/', '/')
      .replaceAll(r'\\/', '/')
      .replaceAll(r'\u002F', '/')
      .replaceAll(r'\u002f', '/')
      .replaceAll(r'\u0026', '&')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#x2f;', '/')
      .replaceAll('&#47;', '/');

  String? _cleanUrl(String? value, Uri baseUri) {
    if (value == null) return null;
    var url = _decodeHtml(value).trim();
    if (url.isEmpty || url.startsWith('#') || url.toLowerCase().startsWith('javascript:')) return null;
    try { url = Uri.decodeComponent(url); } catch (_) {}
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) {
      final resolved = Uri.tryParse(baseUri.resolve(url).toString());
      if (resolved == null || resolved.host.isEmpty) return null;
      return resolved.toString();
    }
    if (!parsed.hasScheme) return baseUri.resolve(url).toString();
    return parsed.toString();
  }

  String? _extractDirectUrl(String html, Uri baseUri) {
    final decoded = _decodeHtml(html);
    final patterns = <RegExp>[
      RegExp(r'''href\s*=\s*["'](https?://download[^"']+)["']''', caseSensitive: false),
      RegExp(r'''href\s*=\s*["'](https?://[^"']*mediafire[^"']*download[^"']+)["']''', caseSensitive: false),
      RegExp(r'''(?:"|')download_url(?:"|')\s*:\s*(?:"|')([^"']+)(?:"|')''', caseSensitive: false),
      RegExp(r'''(?:"|')downloadLink(?:"|')\s*:\s*(?:"|')([^"']+)(?:"|')''', caseSensitive: false),
      RegExp(r'''data-download-url\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''downloadUrl\s*[:=]\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''(https?://download[^"' <>\s]+)''', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(decoded)) {
        final candidate = _cleanUrl(match.group(1), baseUri);
        if (candidate == null) continue;
        final uri = Uri.tryParse(candidate);
        if (uri == null || uri.host.isEmpty) continue;
        if (candidate.toLowerCase().contains('/file/') && !candidate.toLowerCase().contains('download')) continue;
        return candidate;
      }
    }
    return null;
  }

  String? _extractContinueUrl(String html, Uri baseUri) {
    final decoded = _decodeHtml(html);
    final patterns = <RegExp>[
      RegExp(r'''<a[^>]+id\s*=\s*["']continue-btn["'][^>]+href\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''<a[^>]+href\s*=\s*["']([^"']+)["'][^>]+id\s*=\s*["']continue-btn["']''', caseSensitive: false),
      RegExp(r'''id\s*=\s*["']continue-btn["'][^>]*href\s*=\s*["']([^"']+)["']''', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final result = _cleanUrl(pattern.firstMatch(decoded)?.group(1), baseUri);
      if (result != null) return result;
    }
    return null;
  }

  Future<String?> _getDirectMediaFireUrl(String pageUrl) async {
    _mediaFireCookieHeader = '';
    var currentUrl = pageUrl;
    for (var attempt = 0; attempt < 5; attempt++) {
      final response = await _dio.get<String>(
        currentUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 30),
          headers: _requestHeaders(),
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );
      _storeCookies(response.headers);
      final html = response.data;
      if (html == null || html.trim().isEmpty) throw Exception('صفحة MediaFire فارغة.');
      final baseUri = response.realUri;
      final direct = _extractDirectUrl(html, baseUri);
      if (direct != null) return direct;
      final lower = html.toLowerCase();
      final continueUrl = _extractContinueUrl(html, baseUri);
      if (continueUrl != null && attempt < 4) {
        await Future<void>.delayed(const Duration(seconds: 6));
        currentUrl = continueUrl;
        continue;
      }
      if (lower.contains('captcha') || lower.contains('cloudflare')) throw Exception('MediaFire طلب التحقق من أن المستخدم ليس روبوتًا.');
      if (lower.contains('sign in') && lower.contains('mediafire')) throw Exception('MediaFire يطلب تسجيل الدخول قبل الوصول للملف.');
      if (lower.contains('generating new download key')) throw Exception('MediaFire لم ينشئ رابط التنزيل بعد. حاول مرة أخرى.');
      throw Exception('لم يتم العثور على رابط التنزيل في صفحة MediaFire.');
    }
    throw Exception('تعذر الوصول إلى رابط الملف الحقيقي من MediaFire.');
  }

  String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout: return 'انتهت مهلة الاتصال بـ MediaFire.';
      case DioExceptionType.sendTimeout: return 'انتهت مهلة إرسال الطلب.';
      case DioExceptionType.receiveTimeout: return 'انتهت مهلة استقبال البيانات.';
      case DioExceptionType.transformTimeout: return 'انتهت مهلة معالجة البيانات. يرجى المحاولة مرة أخرى.';
      case DioExceptionType.connectionError: return 'تعذر الاتصال بالإنترنت.';
      case DioExceptionType.badResponse: return 'MediaFire أعاد خطأ HTTP ${error.response?.statusCode ?? ''}.';
      case DioExceptionType.cancel: return 'تم إلغاء عملية التحميل.';
      case DioExceptionType.badCertificate: return 'تعذر التحقق من شهادة الاتصال الآمن.';
      case DioExceptionType.unknown: return 'حدث خطأ غير معروف أثناء الاتصال بـ MediaFire.';
    }
  }

  String _sanitizeTitle(String value) => value.replaceAll(RegExp(r'''[\\/:*?"<>|]'''), '_').trim().isEmpty ? 'kitara_file' : value.replaceAll(RegExp(r'''[\\/:*?"<>|]'''), '_').trim();

  String _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      for (final segment in uri.pathSegments.reversed) {
        final decoded = Uri.decodeComponent(segment.replaceAll('+', ' '));
        final dot = decoded.lastIndexOf('.');
        if (dot > 0 && dot < decoded.length - 1) {
          final extension = decoded.substring(dot + 1).toLowerCase();
          if (extension.length <= 5 && RegExp(r'^[a-z0-9]+$').hasMatch(extension)) return extension;
        }
      }
    } catch (_) {}
    return '';
  }

  String _createFileName() {
    final title = _sanitizeTitle(widget.book.title);
    final extension = _getExtensionFromUrl(widget.book.downloadUrl);
    return extension.isEmpty ? '$title.cbr' : '$title.$extension';
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.cbr')) return 'application/vnd.comicbook-rar';
    if (lower.endsWith('.cbz')) return 'application/vnd.comicbook+zip';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.epub')) return 'application/epub+zip';
    if (lower.endsWith('.rar')) return 'application/vnd.rar';
    return 'application/octet-stream';
  }

  Future<List<int>> _readHeader(File file) async {
    final bytes = <int>[];
    await for (final chunk in file.openRead(0, 16)) {
      bytes.addAll(chunk);
      if (bytes.length >= 16) break;
    }
    return bytes;
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) if (bytes[i] != signature[i]) return false;
    return true;
  }

  bool _isValidBookFile(String contentType) {
    final type = contentType.toLowerCase();
    if (type.contains('text/html') || type.contains('application/json') || type.startsWith('text/')) return false;
    return _startsWith(_lastHeader, [0x25, 0x50, 0x44, 0x46]) ||
        _startsWith(_lastHeader, [0x50, 0x4B, 0x03, 0x04]) ||
        _startsWith(_lastHeader, [0x50, 0x4B, 0x05, 0x06]) ||
        _startsWith(_lastHeader, [0x50, 0x4B, 0x07, 0x08]) ||
        _startsWith(_lastHeader, [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07]);
  }

  String _getUserFriendlyError(Object error) {
    final message = error.toString();
    if (message.contains('INVALID_DOWNLOAD_RESPONSE')) return 'MediaFire أعاد صفحة ويب بدل الملف الحقيقي. لم يتم حفظ ملف غير صالح.';
    if (message.contains('PUBLIC_SAVE_FAILED')) return 'تم تنزيل الملف، لكن تعذر حفظه في مجلد التنزيلات.';
    if (message.contains('TEMP_FILE_NOT_FOUND')) return 'فشل إنشاء الملف المؤقت أثناء التنزيل.';
    if (message.contains('DIRECT_URL_NOT_FOUND')) return 'تعذر العثور على رابط الملف الحقيقي.';
    if (message.contains('لم يتم العثور على رابط التنزيل')) return 'تعذر العثور على رابط تنزيل الملف في MediaFire.';
    if (message.contains('Generating') || message.contains('لم ينشئ رابط التنزيل')) return 'MediaFire لم يجهز رابط الملف بعد. حاول مرة أخرى.';
    if (message.contains('طلب التحقق')) return 'MediaFire طلب التحقق قبل تنزيل الملف. حاول مرة أخرى لاحقًا.';
    if (message.contains('تعذر الاتصال بالإنترنت')) return 'تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
    if (message.contains('انتهت مهلة')) return 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى.';
    var clean = message.replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '[الرابط مخفي]').replaceFirst('Exception: ', '');
    if (clean.length > 300) clean = clean.substring(0, 300);
    return clean.isEmpty ? 'حدث خطأ غير معروف أثناء التحميل.' : clean;
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    if (mounted) setState(() { _isDownloading = true; _downloadCompleted = false; _progress = 0.0; _status = 'جاري تجهيز التحميل...'; });
    File? temporaryFile;
    try {
      _mediaFireCookieHeader = '';
      final directUrl = await _getDirectMediaFireUrl(widget.book.downloadUrl);
      if (directUrl == null || directUrl.isEmpty) throw Exception('DIRECT_URL_NOT_FOUND');
      final temporaryDirectory = await getTemporaryDirectory();
      final fileName = _createFileName();
      final temporaryPath = '${temporaryDirectory.path}/$fileName';
      temporaryFile = File(temporaryPath);
      if (await temporaryFile.exists()) await temporaryFile.delete();
      if (mounted) setState(() => _status = 'جاري تنزيل الملف الحقيقي...');
      final response = await _dio.download(
        directUrl,
        temporaryPath,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          final value = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          setState(() { _progress = value; _status = total > 0 ? 'جاري التحميل... ${(value * 100).toInt()}%' : 'جاري التحميل...'; });
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout: const Duration(minutes: 15),
          sendTimeout: const Duration(minutes: 2),
          headers: { ..._requestHeaders(), 'Accept': '*/*', 'Referer': widget.book.downloadUrl },
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );
      if (!await temporaryFile.exists()) throw Exception('TEMP_FILE_NOT_FOUND');
      final fileLength = await temporaryFile.length();
      final contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
      _lastHeader = await _readHeader(temporaryFile);
      if (fileLength < 1024 || !_isValidBookFile(contentType)) throw Exception('INVALID_DOWNLOAD_RESPONSE');
      if (mounted) setState(() => _status = 'جاري حفظ الملف...');

      final savedFile = await _fileSaver.saveFile(
        file: temporaryFile,
        fileName: fileName,
        mimeType: _getMimeType(fileName),
      );
      if (savedFile == null || !savedFile.isSuccess) throw Exception('PUBLIC_SAVE_FAILED');

      // Keep a private persistent copy so KITARA can display the download in "تنزيلاتي".
      await _downloadsService.copyToAppDownloads(
        source: temporaryFile,
        book: widget.book,
        fileName: fileName,
      );

      try { await temporaryFile.delete(); } catch (_) {}
      if (mounted) {
        setState(() { _progress = 1.0; _isDownloading = false; _downloadCompleted = true; _status = 'اكتمل التحميل'; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحميل الملف الحقيقي وإضافته إلى «تنزيلاتي» في KITARA.')));
      }
      _loadRewardedAd();
    } on DioException catch (e) {
      await _cleanupTemporaryFile(temporaryFile);
      if (!mounted) return;
      setState(() { _isDownloading = false; _progress = 0.0; _status = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 8), content: Text('خطأ التحميل:\n${_getDioErrorMessage(e)}')));
      _loadRewardedAd();
    } catch (e, stackTrace) {
      debugPrint('DOWNLOAD ERROR: $e');
      debugPrint('DOWNLOAD STACK TRACE:\n$stackTrace');
      await _cleanupTemporaryFile(temporaryFile);
      if (!mounted) return;
      setState(() { _isDownloading = false; _progress = 0.0; _status = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 10), content: Text('خطأ التحميل:\n${_getUserFriendlyError(e)}')));
      _loadRewardedAd();
    }
  }

  Future<void> _cleanupTemporaryFile(File? file) async {
    if (file == null) return;
    try { if (await file.exists()) await file.delete(); } catch (e) { debugPrint('CLEANUP ERROR: $e'); }
  }

  void _startFreeDownload() { if (!_isDownloading) _startDownload(); }

  @override
  void dispose() { _rewardedAd?.dispose(); _dio.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Scaffold(
      appBar: AppBar(title: const Text('التحميل')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 30),
          const Icon(Icons.download_rounded, size: 80, color: orange),
          const SizedBox(height: 20),
          Text(widget.book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 35),
          if (!_isDownloading && !_downloadCompleted)
            ElevatedButton.icon(
              onPressed: _startFreeDownload,
              icon: const Icon(Icons.download_rounded),
              label: const Text('بدء التحميل'),
              style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(55)),
            ),
          if (_isDownloading || _downloadCompleted) ...[
            const SizedBox(height: 10),
            Text(_status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _downloadCompleted ? Colors.green : null)),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress, minHeight: 10, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toInt()}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (_downloadCompleted) ...[
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, size: 55, color: Colors.green),
              const SizedBox(height: 10),
              const Text('تمت إضافة الملف إلى «تنزيلاتي»', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ],
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
