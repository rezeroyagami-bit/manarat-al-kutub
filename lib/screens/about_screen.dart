import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حول كِتارا',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/kitara_icon.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            const Text(
              'KITARA — كِتارا',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: orange,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'كيتارا تطبيق عربي يهدف إلى جمع الكتب والمجلات في مكان واحد، لتسهيل اكتشاف المحتوى وقراءته والوصول إليه بطريقة بسيطة ومريحة.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'نؤمن أن لكل كتاب حكاية، وأن كل صفحة يمكن أن تفتح بابًا جديدًا للمعرفة والخيال.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'يتم نشر الكتب والمجلات والروابط داخل التطبيق فقط عندما يكون استخدامها أو توزيعها مصرحًا به من أصحاب الحقوق أو وفق الترخيص المناسب.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Text(
                    'KITARA — كِتارا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'كل صفحة... بداية حكاية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'تم إنشاء التطبيق بواسطة ز . م',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
