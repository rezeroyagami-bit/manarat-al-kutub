import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك المميز'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.workspace_premium,
              size: 90,
            ),
            const SizedBox(height: 20),
            const Text(
              'اشترك في منارة الكتب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'استمتع بالتحميل المباشر للكتب والمجلات '
              'بدون الحاجة إلى مشاهدة الإعلانات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'سيتم ربط الدفع والاشتراك لاحقًا.',
                    ),
                  ),
                );
              },
              child: const Text('اشتراك شهري'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'سيتم ربط الدفع والاشتراك لاحقًا.',
                    ),
                  ),
                );
              },
              child: const Text('اشتراك سنوي'),
            ),
          ],
        ),
      ),
    );
  }
}
