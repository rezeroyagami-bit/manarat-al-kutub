import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';

class DownloadOptionsScreen extends StatelessWidget {
  final Book book;

  const DownloadOptionsScreen({
    super.key,
    required this.book,
  });

  Future<void> openDownloadLink() async {
    final uri = Uri.parse(book.downloadUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خيارات التحميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.download,
              size: 80,
            ),

            const SizedBox(height: 20),

            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'التحميل المباشر سيكون متاحًا للمشتركين المدفوعين.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium),
              label: const Text('تحميل مباشر — للمشتركين'),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('تحميل مجاني'),
                      content: const Text(
                        'شاهد الإعلان أولًا، وبعد انتهاء الإعلان سيتم فتح رابط التحميل.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);

                            await Future.delayed(
                              const Duration(seconds: 3),
                            );

                            if (context.mounted) {
                              await openDownloadLink();
                            }
                          },
                          child: const Text('مشاهدة الإعلان'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('تحميل مجاني — شاهد إعلانًا'),
            ),

            const SizedBox(height: 20),

            const Text(
              'ملاحظة: النسخة الحالية تحاكي الإعلان لمدة 3 ثوانٍ. '
              'سيتم ربط إعلان Rewarded حقيقي لاحقًا.',
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
