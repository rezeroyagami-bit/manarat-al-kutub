import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static const _repoApi =
      'https://api.github.com/repos/rezeroyagami-bit/manarat-al-kutub/releases/latest';
  static const _updateProxyUrl =
      'https://gftlkxpzympplwluxmah.supabase.co/functions/v1/kitara-update';

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
                    if (total > 0) {
                      setState(() => progress = received / total);
                    }
                  },
                  options: Options(
                    followRedirects: true,
                    receiveTimeout: const Duration(minutes: 10),
                    sendTimeout: const Duration(minutes: 2),
                  ),
                );

                setState(() {
                  downloading = false;
                  downloaded = true;
                  progress = 1;
                });

                final result = await OpenFilex.open(
                  apkPath,
                  type: 'application/vnd.android.package-archive',
                );
                if (result.type != ResultType.done && context.mounted) {
                  setState(() => error = 'تعذر بدء تثبيت التحديث.');
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
                  Text(
                    'الإصدار الجديد: $latestVersion',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('يمكنك تحديث التطبيق مباشرة دون حذف النسخة الحالية.'),
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
                  onPressed: downloading ? null : startDownload,
                  child: Text(downloaded ? 'تثبيت' : 'تحديث الآن'),
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
      final latestBuild = int.tryParse(tag.replaceFirst(RegExp(r'^v'), ''));
      if (latestBuild == null || latestBuild <= currentBuild) return null;

      final assets = (data['assets'] as List?) ?? const [];
      final hasApk = assets.any(
        (asset) => (asset as Map<String, dynamic>)['name'] == 'kitara.apk',
      );
      if (!hasApk) return null;

      return {
        'version': tag.isNotEmpty ? tag : latestBuild.toString(),
        'downloadUrl': _updateProxyUrl,
      };
    } catch (_) {
      return null;
    }
  }
}
