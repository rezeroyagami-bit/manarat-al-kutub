import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  final int buildNumber;
  final String versionName;
  final String downloadUrl;

  const AppUpdateInfo({
    required this.buildNumber,
    required this.versionName,
    required this.downloadUrl,
  });
}

class AppUpdateService {
  static const _latestReleaseUrl =
      'https://api.github.com/repos/rezeroyagami-bit/manarat-al-kutub/releases/latest';

  // ضع رابط APK هنا لاحقًا إذا أردت استخدام رابط ثابت خاص بك.
  // اتركه فارغًا لاستخدام رابط أحدث إصدار من GitHub تلقائيًا.
  static const customUpdateUrl = '';

  final Dio _dio = Dio();

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final package = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(package.buildNumber) ?? 0;
      final response = await _dio.get<Map<String, dynamic>>(
        _latestReleaseUrl,
        options: Options(headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'KITARA-App',
        }),
      );
      final data = response.data;
      if (data == null) return null;

      final tag = (data['tag_name'] ?? '').toString();
      final latestBuild = int.tryParse(tag.replaceFirst(RegExp(r'^v'), ''));
      if (latestBuild == null || latestBuild <= currentBuild) return null;

      final assets = data['assets'];
      if (assets is! List) return null;
      Map<String, dynamic>? apk;
      for (final item in assets) {
        if (item is Map && item['name']?.toString() == 'kitara.apk') {
          apk = Map<String, dynamic>.from(item);
          break;
        }
      }

      final githubUrl = apk?['browser_download_url']?.toString() ?? '';
      final url = customUpdateUrl.trim().isNotEmpty ? customUpdateUrl.trim() : githubUrl;
      if (url.isEmpty) return null;

      return AppUpdateInfo(
        buildNumber: latestBuild,
        versionName: tag,
        downloadUrl: url,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> downloadAndInstall(AppUpdateInfo info) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/kitara-update-${info.buildNumber}.apk');
      if (await file.exists()) await file.delete();

      await _dio.download(
        info.downloadUrl,
        file.path,
        options: Options(
          headers: const {'User-Agent': 'KITARA-App'},
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 10,
        ),
      );

      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  Future<void> showUpdateDialog(BuildContext context, {bool manual = false}) async {
    final info = await checkForUpdate();
    if (!context.mounted) return;

    if (info == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كِتارا محدثة إلى آخر إصدار.')),
        );
      }
      return;
    }

    var downloading = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تحديث جديد متوفر'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'يتوفر إصدار جديد من كِتارا (${info.versionName}).\n\nيمكنك تنزيل التحديث وتثبيته دون حذف النسخة الحالية.',
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    info.downloadUrl,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: downloading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('لاحقًا'),
                ),
                FilledButton.icon(
                  onPressed: downloading
                      ? null
                      : () async {
                          setState(() => downloading = true);
                          final ok = await downloadAndInstall(info);
                          if (!dialogContext.mounted) return;
                          if (ok) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            setState(() => downloading = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('تعذر بدء تنزيل التحديث.')),
                            );
                          }
                        },
                  icon: downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_rounded),
                  label: Text(downloading ? 'جاري التنزيل...' : 'تنزيل التحديث'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void dispose() {
    _dio.close(force: true);
  }
}
