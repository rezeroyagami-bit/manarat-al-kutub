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
    const gold = Color(0xFFF2A900);
    const green = Color(0xFF2E7D32);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 190,
                    child: CustomPaint(
                      painter: _PuzzledReaderPainter(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: gold,
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

class _PuzzledReaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A3518), Color(0xFF21150F)],
      ).createShader(bounds);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(22)),
      background,
    );

    final shelfPaint = Paint()
      ..color = const Color(0xFF170F0B)
      ..style = PaintingStyle.fill;
    final shelfEdge = Paint()
      ..color = const Color(0xFFD08A32)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Library shelves on both sides.
    for (final left in [true, false]) {
      final x = left ? 12.0 : size.width - 78.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 24, 66, 137),
          const Radius.circular(5),
        ),
        shelfPaint,
      );
      for (var row = 0; row < 3; row++) {
        final y = 62.0 + row * 43;
        canvas.drawLine(Offset(x + 3, y), Offset(x + 63, y), shelfEdge);
        for (var book = 0; book < 4; book++) {
          final bx = x + 7 + book * 14.0;
          final bookPaint = Paint()
            ..color = [
              const Color(0xFFB8752C),
              const Color(0xFF8E4D24),
              const Color(0xFFD6A34A),
              const Color(0xFF6E3920),
            ][(book + row) % 4];
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(bx, y - 31 + (book % 2) * 3, 10, 29 - (book % 2) * 3),
              const Radius.circular(2),
            ),
            bookPaint,
          );
        }
      }
    }

    // Soft light at the end of the aisle.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD58A).withValues(alpha: 0.42),
          const Color(0xFFFFD58A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, 82),
        radius: 100,
      ));
    canvas.drawCircle(Offset(size.width / 2, 82), 100, glow);

    // Question mark above the reader.
    final question = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFFFFC15A),
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    question.paint(canvas, Offset(size.width / 2 - question.width / 2, 5));

    // Standing reader, seen from behind, with one hand on his head.
    final person = Paint()..color = const Color(0xFF17110E);
    final outline = Paint()
      ..color = const Color(0xFF9B642D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 73),
        width: 35,
        height: 43,
      ),
      person,
    );

    final body = Path()
      ..moveTo(size.width / 2 - 34, 101)
      ..quadraticBezierTo(size.width / 2, 88, size.width / 2 + 34, 101)
      ..lineTo(size.width / 2 + 42, 170)
      ..lineTo(size.width / 2 - 42, 170)
      ..close();
    canvas.drawPath(body, person);
    canvas.drawPath(body, outline);

    // Backpack.
    final bag = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 25, 111, 50, 52),
      const Radius.circular(12),
    );
    canvas.drawRRect(bag, Paint()..color = const Color(0xFF302018));
    canvas.drawRRect(bag, outline);
    canvas.drawLine(
      Offset(size.width / 2 - 17, 119),
      Offset(size.width / 2 - 17, 157),
      outline,
    );
    canvas.drawLine(
      Offset(size.width / 2 + 17, 119),
      Offset(size.width / 2 + 17, 157),
      outline,
    );

    // Raised arm and hand resting on the head: puzzled pose.
    final arm = Path()
      ..moveTo(size.width / 2 + 25, 108)
      ..quadraticBezierTo(size.width / 2 + 49, 93, size.width / 2 + 37, 72)
      ..lineTo(size.width / 2 + 22, 61)
      ..lineTo(size.width / 2 + 12, 69)
      ..quadraticBezierTo(size.width / 2 + 25, 82, size.width / 2 + 15, 98)
      ..close();
    canvas.drawPath(arm, person);
    canvas.drawPath(arm, outline);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 + 17, 65),
        width: 17,
        height: 13,
      ),
      person,
    );

    // A few foreground books.
    for (var i = 0; i < 3; i++) {
      final y = 174.0 + i * 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24 + i * 7.0, y, 52, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFD49A45),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - 76 + i * 7.0, y, 52, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF9B5A2C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
