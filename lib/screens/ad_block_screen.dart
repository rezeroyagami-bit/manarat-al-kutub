import 'package:flutter/material.dart';

class AdBlockScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const AdBlockScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded, size: 52, color: orange),
                ),
                const SizedBox(height: 26),
                const Text(
                  'تم اكتشاف مانع الإعلانات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Text(
                  'لا يمكنك تصفح محتوى كِتارا أثناء استخدام مانع الإعلانات.\n\n'
                  'للمواصلة، يرجى تعطيل مانع الإعلانات ثم الضغط على «إعادة المحاولة».',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 17, height: 1.7, color: Colors.grey),
                ),
                const SizedBox(height: 28),
                SizedBox(width: 210, child: ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
