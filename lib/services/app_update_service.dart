import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static const _repoApi =
      'https://api.github.com/repos/rezeroyagami-bit/manarat-al-kutub/releases/latest';

  Future<void> showUpdateDialog(BuildContext context) async {
    final update = await _checkForUpdate();
    if (!context.mounted || update == null) return;

    final latestVersion = update['version'] as String;
    final downloadUrl = update['downloadUrl'] as String;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool downloading = false;
        bool downloaded = false;
        double progress = 0;
        String? error;
        String? downloadedApkPath;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> startDownload() async {
              setState(() {
                downloading = true;
                error = null;
                progress = 0;
              });

              try {
                final dir = Directory.systemTemp;
                final apkPath = '${dir.path}/kitara-update-$latestVersion.apk';
                await Dio().download(
                  downloadUrl,
                  apkPath,
                  onReceiveProgress: (received, total) {
                    if (total > 0 && context.mounted) {
                      setState(() => progress = received / total);
                    }
                  },
                  options: Options(
                    followRedirects: true,
                    receiveTimeout: const Duration(minutes: 10),
                    sendTimeout: const Duration(minutes: 2),
                  ),
                );

                final apkFile = File(apkPath);
                if (!await apkFile.exists() || await apkFile.length() < 1024 * 1024) {
                  throw Exception('INVALID_UPDATE_FILE');
                }
                if (!context.mounted) return;
                setState(() {
                  downloading = false;
                  downloaded = true;
                  downloadedApkPath = apkPath;
                  progress = 1;
                });

                final result = await OpenFilex.open(
                  apkPath,
                  type: 'application/vnd.android.package-archive',
                );
                if (result.type != ResultType.done && context.mounted) {
                  setState(() => error = 'لم يبدأ مُثبّت Android. افتح الملف من التنزيلات واسمح بالتثبيت لهذا التطبيق عند الطلب.');
                }
              } catch (_) {
                if (context.mounted) {
                  setState(() {
                    downloading = false;
                    error = 'تعذر تنزيل التحديث.';
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('تحديث جديد متوفر'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإصدار الجديد: $latestVersion\nسيطلب Android تأكيد التثبيت. عند استخدام مفتاح التوقيع نفسه ستبقى بياناتك وإعداداتك محفوظة.'),
                  if (downloading) ...[
                    const SizedBox(height: 18),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('جارٍ تنزيل التحديث... ${(progress * 100).round()}%'),
                  ],
                  if (downloaded && !downloading) ...[
                    const SizedBox(height: 12),
                    const Text('تم تنزيل التحديث. جارٍ فتح التثبيت...'),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: downloading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('لاحقًا'),
                ),
                FilledButton(
                  onPressed: downloading
                      ? null
                      : downloaded && downloadedApkPath != null
                          ? () => OpenFilex.open(
                                downloadedApkPath!,
                                type: 'application/vnd.android.package-archive',
                              )
                          : startDownload,
                  child: Text(downloaded ? 'إعادة فتح التثبيت' : 'تحديث الآن'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await Dio().get(
        _repoApi,
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final tag = (data['tag_name'] ?? '').toString().trim();
      final latestBuild = int.tryParse(tag.replaceFirst(RegExp(r'^v', caseSensitive: false), ''));
      if (latestBuild == null || latestBuild <= currentBuild) return null;

      final assets = (data['assets'] as List?) ?? const [];
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        if (asset is Map<String, dynamic> && asset['name'] == 'kitara.apk') {
          apkAsset = asset;
          break;
        }
      }
      if (apkAsset == null || (apkAsset['browser_download_url'] ?? '').toString().isEmpty) return null;

      return {
        'version': latestBuild.toString(),
        'downloadUrl': apkAsset['browser_download_url'].toString(),
        'releaseUrl': (data['html_url'] ?? '').toString(),
      };
    } catch (_) {
      return null;
    }
  }
}
