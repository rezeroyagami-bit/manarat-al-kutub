import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

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

  bool _earnedReward = false;

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

  Future<String?> _getDirectMediaFireUrl(
    String pageUrl,
  ) async {
    try {
      final response = await _dio.get<String>(
        pageUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) {
            return status != null &&
                status >= 200 &&
                status < 400;
          },
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/140.0 Mobile Safari/537.36',
          },
        ),
      );

      final html = response.data;

      if (html == null || html.isEmpty) {
        return null;
      }

      final decodedHtml = html
          .replaceAll(r'\/', '/')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#x2F;', '/');

      final patterns = <RegExp>[
        RegExp(
          r'href=["''](https?://download[^"'']+)["'']',
          caseSensitive: false,
        ),
        RegExp(
          r'"download_url"\s*:\s*"([^"]+)"',
          caseSensitive: false,
        ),
        RegExp(
          r'"downloadLink"\s*:\s*"([^"]+)"',
          caseSensitive: false,
        ),
        RegExp(
          r'data-download-url=["'']([^"'']+)["'']',
          caseSensitive: false,
        ),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(decodedHtml);

        if (match != null) {
          var url = match.group(1);

          if (url != null && url.isNotEmpty) {
            url = url.replaceAll(r'\u0026', '&');

            try {
              return Uri.decodeComponent(url);
            } catch (_) {
              return url;
            }
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _createFileName() {
    final title = widget.book.title
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .trim();

    final extension = _getExtensionFromUrl(
      widget.book.downloadUrl,
    );

    return extension.isEmpty
        ? '$title.cbr'
        : '$title.$extension';
  }

  String _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      final segments = uri.pathSegments;

      for (final segment in segments.reversed) {
        final decoded = Uri.decodeComponent(
          segment.replaceAll('+', ' '),
        );

        final dot = decoded.lastIndexOf('.');

        if (dot > 0 && dot < decoded.length - 1) {
          final extension = decoded.substring(dot + 1);

          if (extension.length <= 5) {
            return extension.toLowerCase();
          }
        }
      }
    } catch (_) {}

    return '';
  }

  Future<Directory> _getDownloadDirectory() async {
    final baseDirectory =
        await getApplicationDocumentsDirectory();

    final downloadDirectory = Directory(
      '${baseDirectory.path}/downloads',
    );

    if (!await downloadDirectory.exists()) {
      await downloadDirectory.create(
        recursive: true,
      );
    }

    return downloadDirectory;
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadCompleted = false;
        _progress = 0.0;
        _status = 'جاري تجهيز التحميل...';
      });
    }

    try {
      final directUrl =
          await _getDirectMediaFireUrl(
        widget.book.downloadUrl,
      );

      if (directUrl == null || directUrl.isEmpty) {
        throw Exception(
          'DIRECT_URL_NOT_FOUND',
        );
      }

      final directory =
          await _getDownloadDirectory();

      final fileName = _createFileName();

      final filePath =
          '${directory.path}/$fileName';

      if (mounted) {
        setState(() {
          _status = 'جاري التحميل...';
        });
      }

      await _dio.download(
        directUrl,
        filePath,
        deleteOnError: true,
        onReceiveProgress:
            (received, total) {
          if (!mounted) return;

          if (total > 0) {
            final value =
                received / total;

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
          followRedirects: true,
          receiveTimeout:
              const Duration(minutes: 10),
          sendTimeout:
              const Duration(minutes: 2),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 15)',
          },
        ),
      );

      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception(
          'DOWNLOAD_FILE_NOT_FOUND',
        );
      }

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _isDownloading = false;
          _downloadCompleted = true;
          _status = 'اكتمل التحميل';
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'اكتمل تحميل الملف بنجاح.',
            ),
          ),
        );
      }

      _loadRewardedAd();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _progress = 0.0;
        _status = '';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر بدء التحميل من المصدر حاليًا.',
          ),
        ),
      );

      _loadRewardedAd();
    }
  }

  void _startFreeDownload() {
    if (_isDownloading) return;

    _showRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.download_rounded,
              size: 80,
              color: orange,
            ),

            const SizedBox(height: 20),

            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            if (!_isDownloading &&
                !_downloadCompleted)
              ElevatedButton.icon(
                onPressed: _startFreeDownload,
                icon: const Icon(
                  Icons.download_rounded,
                ),
                label: const Text(
                  'تحميل — شاهد إعلانًا',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFF28C28),
                  foregroundColor:
                      Colors.white,
                  minimumSize:
                      const Size.fromHeight(55),
                ),
              ),

            if (_isDownloading ||
                _downloadCompleted) ...[
              const SizedBox(height: 10),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      _downloadCompleted
                          ? Colors.green
                          : null,
                ),
              ),

              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                borderRadius:
                    BorderRadius.circular(10),
              ),

              const SizedBox(height: 12),

              Text(
                '${(_progress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              if (_downloadCompleted) ...[
                const SizedBox(height: 20),

                const Icon(
                  Icons.check_circle,
                  size: 55,
                  color: Colors.green,
                ),

                const SizedBox(height: 10),

                const Text(
                  'تم حفظ الملف في تنزيلات كِتارا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            if (_isLoadingAd &&
                !_isDownloading &&
                !_downloadCompleted)
              const Text(
                'جاري تجهيز الإعلان...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
