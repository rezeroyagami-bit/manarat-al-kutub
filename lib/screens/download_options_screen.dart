import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../models/book.dart';

class DownloadOptionsScreen extends StatefulWidget {
  final Book book;

  const DownloadOptionsScreen({
    super.key,
    required this.book,
  });

  @override
  State<DownloadOptionsScreen> createState() =>
      _DownloadOptionsScreenState();
}

class _DownloadOptionsScreenState
    extends State<DownloadOptionsScreen> {
  RewardedAd? _rewardedAd;

  bool _isLoadingAd = false;
  bool _isDownloading = false;
  bool _downloadCompleted = false;

  double _progress = 0.0;
  String _status = '';

  static const String _rewardedAdUnitId =
      'ca-app-pub-6792981270949925/4708033165';

  final Dio _dio = Dio();
  final PublicFileSaver _fileSaver = PublicFileSaver();

  bool _earnedReward = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  // ============================================================
  // الإعلانات
  // ============================================================

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

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
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
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _earnedReward = false;

              _loadRewardedAd();

              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تعذر تشغيل الإعلان. حاول مرة أخرى.',
                    ),
                  ),
                );
              }
            },
          );

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingAd = false;

          debugPrint(
            'REWARDED AD LOAD ERROR: ${error.message}',
          );

          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isDownloading) return;

    final ad = _rewardedAd;

    if (ad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الإعلان غير جاهز حاليًا. حاول مرة أخرى بعد قليل.',
          ),
        ),
      );

      _loadRewardedAd();
      return;
    }

    _rewardedAd = null;
    _earnedReward = false;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        _earnedReward = true;
      },
    );
  }

  // ============================================================
  // استخراج رابط MediaFire
  // ============================================================

  Future<String?> _getDirectMediaFireUrl(
    String pageUrl,
  ) async {
    try {
      debugPrint(
        'MEDIAFIRE PAGE REQUEST STARTED',
      );

      final response = await _dio.get<String>(
        pageUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout:
              const Duration(seconds: 30),
          sendTimeout:
              const Duration(seconds: 30),
          validateStatus: (status) {
            return status != null &&
                status >= 200 &&
                status < 400;
          },
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 15) '
                'AppleWebKit/537.36 '
                '(KHTML, like Gecko) '
                'Chrome/140.0 Mobile Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,'
                'application/xml;q=0.9,image/avif,'
                'image/webp,*/*;q=0.8',
            'Accept-Language':
                'ar-DZ,ar;q=0.9,en-US;q=0.8,en;q=0.7',
            'Cache-Control': 'no-cache',
          },
        ),
      );

      final html = response.data;

      debugPrint(
        'MEDIAFIRE HTTP STATUS: ${response.statusCode}',
      );

      if (html == null || html.trim().isEmpty) {
        throw Exception(
          'صفحة MediaFire فارغة.',
        );
      }

      debugPrint(
        'MEDIAFIRE HTML LENGTH: ${html.length}',
      );

      // فك بعض أنواع الترميز الموجودة في HTML/JSON.
      var decodedHtml = html;

      decodedHtml = decodedHtml
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

      // ========================================================
      // أنماط متعددة للبحث عن رابط التنزيل.
      // ========================================================

      final patterns = <RegExp>[
        // href="https://download...."
        RegExp(
          r'''href\s*=\s*["'](https?://download[^"']+)["']''',
          caseSensitive: false,
        ),

        // href='https://download....'
        RegExp(
          r'''href\s*=\s*["'](https?://[^"']*mediafire[^"']*download[^"']+)["']''',
          caseSensitive: false,
        ),

        // "download_url":"https://..."
        RegExp(
          r'''"download_url"\s*:\s*"([^"]+)"''',
          caseSensitive: false,
        ),

        // "downloadLink":"https://..."
        RegExp(
          r'''"downloadLink"\s*:\s*"([^"]+)"''',
          caseSensitive: false,
        ),

        // data-download-url="..."
        RegExp(
          r'''data-download-url\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ),

        // downloadUrl:"..."
        RegExp(
          r'''downloadUrl\s*:\s*["']([^"']+)["']''',
          caseSensitive: false,
        ),

        // أي رابط يبدأ بـ download داخل HTML
        RegExp(
          r'''(https?://download[^"' <>\s]+)''',
          caseSensitive: false,
        ),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(
          decodedHtml,
        );

        if (match == null) {
          continue;
        }

        var url = match.group(1);

        if (url == null || url.trim().isEmpty) {
          continue;
        }

        url = url.trim();

        // إزالة علامات نهاية غير مرغوبة.
        url = url
            .replaceAll(r'\u0026', '&')
            .replaceAll(r'\/', '/')
            .replaceAll('&amp;', '&')
            .replaceAll('"', '')
            .replaceAll("'", '');

        try {
          url = Uri.decodeComponent(url);
        } catch (_) {
          // إذا لم يكن URL مشفرًا بالكامل،
          // نستخدمه كما هو.
        }

        final parsedUri = Uri.tryParse(url);

        if (parsedUri == null ||
            !parsedUri.hasScheme ||
            parsedUri.host.isEmpty) {
          continue;
        }

        debugPrint(
          'MEDIAFIRE DIRECT URL FOUND',
        );

        return url;
      }

      // ========================================================
      // فحص إضافي لوجود صفحة MediaFire نفسها.
      // ========================================================

      final lowerHtml =
          decodedHtml.toLowerCase();

      if (lowerHtml.contains('captcha') ||
          lowerHtml.contains('cloudflare')) {
        throw Exception(
          'MediaFire طلب التحقق من أن المستخدم ليس روبوتًا.',
        );
      }

      if (lowerHtml.contains('sign in') &&
          lowerHtml.contains('mediafire')) {
        throw Exception(
          'MediaFire يطلب تسجيل الدخول قبل الوصول للملف.',
        );
      }

      throw Exception(
        'لم يتم العثور على رابط التنزيل في صفحة MediaFire.',
      );
    } on DioException catch (e) {
      debugPrint(
        'MEDIAFIRE DIO ERROR: ${e.type}',
      );
      debugPrint(
        'MEDIAFIRE DIO MESSAGE: ${e.message}',
      );

      throw Exception(
        _getDioErrorMessage(e),
      );
    } catch (e) {
      debugPrint(
        'MEDIAFIRE ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // رسائل أخطاء الشبكة
  // ============================================================

  String _getDioErrorMessage(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال بـ MediaFire.';

      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة إرسال الطلب.';

      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة استقبال البيانات.';

      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالإنترنت.';

      case DioExceptionType.badResponse:
        return 'MediaFire أعاد خطأ HTTP ${error.response?.statusCode ?? ''}.';

      case DioExceptionType.cancel:
        return 'تم إلغاء عملية التحميل.';

      case DioExceptionType.badCertificate:
        return 'تعذر التحقق من شهادة الاتصال الآمن.';

      case DioExceptionType.unknown:
        return 'حدث خطأ غير معروف أثناء الاتصال بـ MediaFire.';
    }
  }

  // ============================================================
  // اسم الملف
  // ============================================================

  String _createFileName() {
    var title = widget.book.title
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(':', '_')
        .replaceAll('*', '_')
        .replaceAll('?', '_')
        .replaceAll('"', '_')
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll('|', '_')
        .trim();

    if (title.isEmpty) {
      title = 'kitara_file';
    }

    final extension = _getExtensionFromUrl(
      widget.book.downloadUrl,
    );

    if (extension.isEmpty) {
      return '$title.cbr';
    }

    return '$title.$extension';
  }

  String _getExtensionFromUrl(
    String url,
  ) {
    try {
      final uri = Uri.parse(url);

      final segments = uri.pathSegments;

      for (final segment in segments.reversed) {
        final decoded = Uri.decodeComponent(
          segment.replaceAll('+', ' '),
        );

        final dot = decoded.lastIndexOf('.');

        if (dot > 0 &&
            dot < decoded.length - 1) {
          final extension =
              decoded.substring(dot + 1);

          if (extension.length <= 5 &&
              RegExp(
                r'^[a-zA-Z0-9]+$',
              ).hasMatch(extension)) {
            return extension.toLowerCase();
          }
        }
      }
    } catch (e) {
      debugPrint(
        'EXTENSION ERROR: $e',
      );
    }

    return '';
  }

  // ============================================================
  // نوع الملف
  // ============================================================

  String _getMimeType(
    String fileName,
  ) {
    final lowerName =
        fileName.toLowerCase();

    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }

    if (lowerName.endsWith('.cbr')) {
      return 'application/vnd.comicbook-rar';
    }

    if (lowerName.endsWith('.cbz')) {
      return 'application/vnd.comicbook+zip';
    }

    if (lowerName.endsWith('.zip')) {
      return 'application/zip';
    }

    if (lowerName.endsWith('.epub')) {
      return 'application/epub+zip';
    }

    if (lowerName.endsWith('.rar')) {
      return 'application/vnd.rar';
    }

    return 'application/octet-stream';
  }

  // ============================================================
  // رسالة الخطأ للمستخدم
  // ============================================================

  String _getUserFriendlyError(
    Object error,
  ) {
    final message = error.toString();

    if (message.contains(
      'لم يتم العثور على رابط التنزيل',
    )) {
      return 'تعذر العثور على رابط تنزيل الملف في MediaFire.\n'
          'قد تكون صفحة الملف تغيرت أو تمنع الوصول الآلي.';
    }

    if (message.contains(
      'طلب التحقق',
    )) {
      return 'MediaFire طلب التحقق قبل تنزيل الملف.\n'
          'حاول مرة أخرى لاحقًا.';
    }

    if (message.contains(
      'يطلب تسجيل الدخول',
    )) {
      return 'هذا الملف يتطلب تسجيل الدخول إلى MediaFire.';
    }

    if (message.contains(
      'تعذر الاتصال بالإنترنت',
    )) {
      return 'تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
    }

    if (message.contains(
      'انتهت مهلة',
    )) {
      return 'انتهت مهلة الاتصال.\n'
          'تحقق من سرعة الإنترنت وحاول مرة أخرى.';
    }

    if (message.contains(
      'PUBLIC_SAVE_FAILED',
    )) {
      return 'تم تنزيل الملف، لكن تعذر حفظه في مجلد التنزيلات.';
    }

    if (message.contains(
      'TEMP_FILE_NOT_FOUND',
    )) {
      return 'فشل إنشاء الملف المؤقت أثناء التنزيل.';
    }

    // نعرض رسالة الخطأ الحقيقية إذا كانت مفيدة،
    // ولكن لا نعرض أي رابط.
    var cleanMessage = message
        .replaceAll(
          RegExp(
            r'https?://\S+',
            caseSensitive: false,
          ),
          '[الرابط مخفي]',
        )
        .replaceFirst(
          'Exception: ',
          '',
        );

    if (cleanMessage.length > 300) {
      cleanMessage =
          cleanMessage.substring(0, 300);
    }

    return cleanMessage.isEmpty
        ? 'حدث خطأ غير معروف أثناء التحميل.'
        : cleanMessage;
  }

  // ============================================================
  // بدء التحميل
  // ============================================================

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadCompleted = false;
        _progress = 0.0;
        _status =
            'جاري تجهيز التحميل...';
      });
    }

    File? temporaryFile;

    try {
      // --------------------------------------------------------
      // 1. الحصول على رابط MediaFire داخليًا.
      // --------------------------------------------------------

      final directUrl =
          await _getDirectMediaFireUrl(
        widget.book.downloadUrl,
      );

      if (directUrl == null ||
          directUrl.isEmpty) {
        throw Exception(
          'DIRECT_URL_NOT_FOUND',
        );
      }

      // --------------------------------------------------------
      // 2. المجلد المؤقت.
      // --------------------------------------------------------

      final temporaryDirectory =
          await getTemporaryDirectory();

      final fileName =
          _createFileName();

      final temporaryPath =
          '${temporaryDirectory.path}/$fileName';

      temporaryFile =
          File(temporaryPath);

      // إذا كان هناك ملف قديم بنفس الاسم،
      // نحذفه قبل بدء التحميل.
      if (await temporaryFile.exists()) {
        try {
          await temporaryFile.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _status =
              'جاري الاتصال بملف التحميل...';
        });
      }

      // --------------------------------------------------------
      // 3. تنزيل الملف.
      // --------------------------------------------------------

      debugPrint(
        'FILE DOWNLOAD STARTED',
      );

      await _dio.download(
        directUrl,
        temporaryPath,
        deleteOnError: true,
        onReceiveProgress:
            (received, total) {
          if (!mounted) return;

          if (total > 0) {
            var value =
                received / total;

            if (value > 1.0) {
              value = 1.0;
            }

            setState(() {
              _progress = value;
              _status =
                  'جاري التحميل... '
                  '${(value * 100).toInt()}%';
            });
          } else {
            setState(() {
              _status =
                  'جاري التحميل...';
            });
          }
        },
        options: Options(
          responseType:
              ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 10,
          receiveTimeout:
              const Duration(minutes: 15),
          sendTimeout:
              const Duration(minutes: 2),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 15) '
                'AppleWebKit/537.36 '
                '(KHTML, like Gecko) '
                'Chrome/140.0 Mobile Safari/537.36',
            'Accept':
                '*/*',
          },
          validateStatus: (status) {
            return status != null &&
                status >= 200 &&
                status < 400;
          },
        ),
      );

      debugPrint(
        'FILE DOWNLOAD FINISHED',
      );

      // --------------------------------------------------------
      // 4. التأكد من وجود الملف.
      // --------------------------------------------------------

      if (!await temporaryFile.exists()) {
        throw Exception(
          'TEMP_FILE_NOT_FOUND',
        );
      }

      final fileLength =
          await temporaryFile.length();

      debugPrint(
        'TEMP FILE SIZE: $fileLength',
      );

      if (fileLength <= 0) {
        throw Exception(
          'تم إنشاء الملف لكنه فارغ.',
        );
      }

      // --------------------------------------------------------
      // 5. حفظ الملف في Downloads العامة.
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          _status =
              'جاري حفظ الملف في التنزيلات...';
        });
      }

      debugPrint(
        'PUBLIC FILE SAVE STARTED',
      );

      final savedFile =
          await _fileSaver.saveFile(
        file: temporaryFile,
        fileName: fileName,
        mimeType:
            _getMimeType(fileName),
      );

      if (savedFile == null ||
          !savedFile.isSuccess) {
        throw Exception(
          'PUBLIC_SAVE_FAILED',
        );
      }

      debugPrint(
        'PUBLIC FILE SAVE SUCCESS',
      );

      // --------------------------------------------------------
      // 6. حذف الملف المؤقت.
      // --------------------------------------------------------

      try {
        await temporaryFile.delete();
      } catch (e) {
        debugPrint(
          'TEMP FILE DELETE ERROR: $e',
        );
      }

      // --------------------------------------------------------
      // 7. نجاح العملية.
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _isDownloading = false;
          _downloadCompleted = true;
          _status =
              'اكتمل التحميل';
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحميل الملف وحفظه في مجلد التنزيلات.',
            ),
          ),
        );
      }

      _loadRewardedAd();
    } on DioException catch (e) {
      debugPrint(
        'DOWNLOAD DIO ERROR: ${e.type}',
      );
      debugPrint(
        'DOWNLOAD DIO MESSAGE: ${e.message}',
      );

      await _cleanupTemporaryFile(
        temporaryFile,
      );

      if (!mounted) return;

      final errorMessage =
          _getDioErrorMessage(e);

      setState(() {
        _isDownloading = false;
        _progress = 0.0;
        _status = '';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          duration:
              const Duration(seconds: 8),
          content: Text(
            'خطأ التحميل:\n$errorMessage',
          ),
        ),
      );

      _loadRewardedAd();
    } catch (e, stackTrace) {
      debugPrint(
        'DOWNLOAD ERROR: $e',
      );

      debugPrint(
        'DOWNLOAD STACK TRACE:\n$stackTrace',
      );

      await _cleanupTemporaryFile(
        temporaryFile,
      );

      if (!mounted) return;

      final errorMessage =
          _getUserFriendlyError(e);

      setState(() {
        _isDownloading = false;
        _progress = 0.0;
        _status = '';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          duration:
              const Duration(seconds: 10),
          content: Text(
            'خطأ التحميل:\n$errorMessage',
          ),
        ),
      );

      _loadRewardedAd();
    }
  }

  // ============================================================
  // تنظيف الملف المؤقت
  // ============================================================

  Future<void> _cleanupTemporaryFile(
    File? file,
  ) async {
    if (file == null) return;

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint(
        'CLEANUP ERROR: $e',
      );
    }
  }

  // ============================================================
  // الاختبار الحالي
  // التحميل يبدأ مباشرة بدون الإعلان.
  // ============================================================

  void _startFreeDownload() {
    if (_isDownloading) return;

    _startDownload();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _dio.close();
    super.dispose();
  }

  // ============================================================
  // واجهة الشاشة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const orange =
        Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التحميل',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 30,
            ),

            const Icon(
              Icons.download_rounded,
              size: 80,
              color: orange,
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              widget.book.title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // --------------------------------------------------
            // زر بدء التحميل
            // --------------------------------------------------

            if (!_isDownloading &&
                !_downloadCompleted)
              ElevatedButton.icon(
                onPressed:
                    _startFreeDownload,
                icon: const Icon(
                  Icons.download_rounded,
                ),
                label: const Text(
                  'بدء التحميل',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      orange,
                  foregroundColor:
                      Colors.white,
                  minimumSize:
                      const Size.fromHeight(
                    55,
                  ),
                ),
              ),

            // --------------------------------------------------
            // حالة التحميل
            // --------------------------------------------------

            if (_isDownloading ||
                _downloadCompleted) ...[
              const SizedBox(
                height: 10,
              ),

              Text(
                _status,
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      _downloadCompleted
                          ? Colors.green
                          : null,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                '${(_progress * 100).toInt()}%',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              // ------------------------------------------------
              // نجاح التحميل
              // ------------------------------------------------

              if (_downloadCompleted) ...[
                const SizedBox(
                  height: 20,
                ),

                const Icon(
                  Icons.check_circle,
                  size: 55,
                  color: Colors.green,
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'تم حفظ الملف في مجلد التنزيلات',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ],

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
