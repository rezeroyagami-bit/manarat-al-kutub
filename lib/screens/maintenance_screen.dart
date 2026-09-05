import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDownloads;

  const MaintenanceScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onDownloads,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      size: 52,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      height: 1.8,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 230,
                    child: ElevatedButton.icon(
                      onPressed: onDownloads,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('تنزيلاتي'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'الملفات التي تم تنزيلها سابقًا تبقى متاحة دون اتصال بالإنترنت.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
