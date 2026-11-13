import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:koni_archive/io.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Converts a CBR archive into a cached PDF beside the original file.
/// The source archive is never modified or deleted.
class CbrToPdfService {
  static Future<File> convertOrGetCached(String cbrPath) async {
    final source = File(cbrPath);
    if (!await source.exists()) {
      throw Exception('ملف CBR الأصلي غير موجود.');
    }

    final pdfPath = cbrPath.replaceFirst(RegExp(r'\.cbr$', caseSensitive: false), '.pdf');
    final pdfFile = File(pdfPath);
    if (await pdfFile.exists()) {
      final sourceTime = await source.lastModified();
      final pdfTime = await pdfFile.lastModified();
      if (!pdfTime.isBefore(sourceTime) && await pdfFile.length() > 1024) {
        return pdfFile;
      }
    }

    await Isolate.run(() => _convertInBackground(cbrPath, pdfPath));
    if (!await pdfFile.exists() || await pdfFile.length() <= 1024) {
      throw Exception('لم يكتمل إنشاء ملف PDF.');
    }
    return pdfFile;
  }

  static Future<void> _convertInBackground(String sourcePath, String outputPath) async {
    final archive = await openArchiveFile(sourcePath);
    final temporary = File('$outputPath.tmp');
    try {
      final pages = archive.files.where((entry) {
        final path = entry.path.toLowerCase();
        return path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.png') ||
            path.endsWith('.webp') ||
            path.endsWith('.gif') ||
            path.endsWith('.bmp');
      }).toList()
        ..sort((a, b) => _naturalCompare(a.path, b.path));

      if (pages.isEmpty) {
        throw Exception('لم يتم العثور على صفحات صور داخل ملف CBR.');
      }
      if (pages.length > 1500) {
        throw Exception('عدد صفحات المجلة كبير جدًا للتحويل الآمن.');
      }

      final document = pw.Document(compress: true);
      var totalImageBytes = 0;
      for (final entry in pages) {
        final original = await archive.readBytes(entry, maxSize: 50 << 20);
        totalImageBytes += original.length;
        if (totalImageBytes > 512 << 20) {
          throw Exception('حجم صور المجلة أكبر من الحد الآمن للتحويل.');
        }

        final decoded = img.decodeImage(original);
        if (decoded == null) {
          throw Exception('تعذر فك ترميز إحدى صفحات المجلة: ${entry.path}');
        }
        final normalized = img.encodePng(decoded);
        final image = pw.MemoryImage(Uint8List.fromList(normalized));
        final width = decoded.width.toDouble();
        final height = decoded.height.toDouble();

        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(width, height),
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.SizedBox(
              width: width,
              height: height,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            ),
          ),
        );
      }

      if (await temporary.exists()) await temporary.delete();
      await temporary.writeAsBytes(await document.save(), flush: true);
      if (await temporary.length() <= 1024) {
        throw Exception('ملف PDF الناتج غير صالح.');
      }
      if (await File(outputPath).exists()) await File(outputPath).delete();
      await temporary.rename(outputPath);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    } finally {
      await archive.close();
    }
  }

  static int _naturalCompare(String a, String b) {
    final aa = a.toLowerCase().split(RegExp(r'(\d+)'));
    final bb = b.toLowerCase().split(RegExp(r'(\d+)'));
    for (var i = 0; i < aa.length && i < bb.length; i++) {
      final an = int.tryParse(aa[i]);
      final bn = int.tryParse(bb[i]);
      if (an != null && bn != null && an != bn) return an.compareTo(bn);
      final comparison = aa[i].compareTo(bb[i]);
      if (comparison != 0) return comparison;
    }
    return a.compareTo(b);
  }
}
