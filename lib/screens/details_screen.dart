import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import 'download_options_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Book book;

  const DetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool isFavorite = false;
  bool _isUnlocked = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _loadAccessState();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    final favorites = prefs.getStringList('favorite_books') ?? [];

    if (!mounted) return;

    setState(() {
      isFavorite = favorites.contains(widget.book.id.toString());
    });
  }

  Future<void> _loadAccessState() async {
    if (!widget.book.isExclusive) {
      if (mounted) setState(() => _checkingAccess = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList('unlocked_books') ?? [];

    if (!mounted) return;

    setState(() {
      _isUnlocked = unlocked.contains(widget.book.id);
      _checkingAccess = false;
    });
  }

  Future<void> _unlockBook() async {
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('محتوى حصري'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'هذا المحتوى متاح للمستخدمين الذين يملكون كود الوصول. أدخل الكود للمتابعة إلى صفحة التحميل.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'كود الوصول',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('تحقق'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || code == null || code.isEmpty) return;

    try {
      final valid = await SupabaseService().validateBookAccess(
        bookId: widget.book.id,
        code: code,
      );

      if (!mounted) return;

      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كود الوصول غير صحيح.')),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList('unlocked_books') ?? [];
      if (!unlocked.contains(widget.book.id)) {
        unlocked.add(widget.book.id);
        await prefs.setStringList('unlocked_books', unlocked);
      }

      setState(() => _isUnlocked = true);

      _openDownloadOptions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر التحقق من الكود. تحقق من اتصال الإنترنت وحاول مرة أخرى.')),
      );
    }
  }

  void _openDownloadOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DownloadOptionsScreen(book: widget.book),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    final favorites = prefs.getStringList('favorite_books') ?? [];

    final bookId = widget.book.id.toString();

    if (favorites.contains(bookId)) {
      favorites.remove(bookId);
    } else {
      favorites.add(bookId);
    }

    await prefs.setStringList('favorite_books', favorites);

    if (!mounted) return;

    setState(() {
      isFavorite = favorites.contains(bookId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'تمت إضافة الكتاب إلى المفضلة'
              : 'تمت إزالة الكتاب من المفضلة',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الكتاب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                if (widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 390),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(blurRadius: 16, offset: Offset(0, 7), color: Colors.black26),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          widget.book.coverUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 300,
                            width: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: orange.withValues(alpha: 0.10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, size: 90, color: orange),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      width: 220,
                      height: 300,
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.menu_book_rounded, size: 90, color: orange),
                    ),
                  ),
                if (widget.book.isExclusive)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.author,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.book.category,
                  style: const TextStyle(color: orange, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (widget.book.isExclusive) ...[
              const SizedBox(height: 14),
              const Text(
                'محتوى حصري',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
            const SizedBox(height: 24),
            const Text('عن المحتوى', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              widget.book.description ?? 'لا يوجد وصف لهذا الكتاب.',
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _checkingAccess
                    ? null
                    : (widget.book.isExclusive && !_isUnlocked
                        ? _unlockBook
                        : _openDownloadOptions),
                icon: Icon(
                  widget.book.isExclusive && !_isUnlocked
                      ? Icons.lock_outline_rounded
                      : Icons.download_rounded,
                ),
                label: Text(
                  _checkingAccess
                      ? 'جارٍ التحقق...'
                      : (widget.book.isExclusive && !_isUnlocked
                          ? 'إدخال كود الوصول'
                          : 'خيارات التحميل'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
