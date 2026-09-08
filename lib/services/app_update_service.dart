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
  // اتركه فارغًا لاستخدام أحدث إصدار تلقائيًا.
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

  Future<String?> downloadUpdate(
    AppUpdateInfo info, {
    required void Function(int percent) onProgress,
  }) async {
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
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = ((received / total) * 100).round().clamp(0, 100);
            onProgress(percent);
          }
        },
      );

      if (!await file.exists() || await file.length() == 0) return null;
      onProgress(100);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> installUpdate(String filePath) async {
    try {
      final result = await OpenFilex.open(
        filePath,
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
    var downloaded = false;
    var progress = 0;
    String? downloadedFilePath;

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
                children: [
                  Text(
                    downloaded
                        ? 'تم تنزيل التحديث بنجاح. اضغط «تثبيت» لإكمال التحديث.'
                        : 'يتوفر إصدار جديد من كِتارا (${info.versionName}).\n\nيمكنك تنزيل التحديث وتثبيته دون حذف النسخة الحالية.',
                    textDirection: TextDirection.rtl,
                  ),
                  if (downloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: progress / 100),
                    const SizedBox(height: 10),
                    Text(
                      '$progress%',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!downloading && !downloaded)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('لاحقًا'),
                  ),
                if (!downloading && downloaded)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                FilledButton.icon(
                  onPressed: downloading
                      ? null
                      : downloaded
                          ? () async {
                              if (downloadedFilePath == null) return;
                              final ok = await installUpdate(downloadedFilePath!);
                              if (!dialogContext.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('تعذر بدء تثبيت التحديث.')),
                                );
                              }
                            }
                          : () async {
                              setState(() {
                                downloading = true;
                                progress = 0;
                              });
                              final path = await downloadUpdate(
                                info,
                                onProgress: (value) {
                                  if (dialogContext.mounted) {
                                    setState(() => progress = value);
                                  }
                                },
                              );
                              if (!dialogContext.mounted) return;
                              if (path != null) {
                                setState(() {
                                  downloading = false;
                                  downloaded = true;
                                  progress = 100;
                                  downloadedFilePath = path;
                                });
                              } else {
                                setState(() => downloading = false);
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('تعذر تنزيل التحديث.')),
                                );
                              }
                            },
                  icon: downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(downloaded ? Icons.install_mobile_rounded : Icons.download_rounded),
                  label: Text(
                    downloading
                        ? 'جاري التنزيل $progress%'
                        : downloaded
                            ? 'تثبيت'
                            : 'تنزيل التحديث',
                  ),
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
