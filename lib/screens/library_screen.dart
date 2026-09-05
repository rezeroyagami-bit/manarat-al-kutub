import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/supabase_service.dart';
import 'details_screen.dart';
import 'magazine_screen.dart';

class LibraryScreen extends StatefulWidget {
  final List<Book> books;

  const LibraryScreen({super.key, required this.books});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const orange = Color(0xFFF28C28);
  String? _selectedSection;
  String? _selectedSchoolLevel;

  List<Book> get _sectionBooks {
    final section = _selectedSection;
    if (section == null) return const [];
    if (section == 'المجلات') return widget.books.where((book) => book.isMagazine).toList();
    if (section == 'الكتب') return widget.books.where((book) => !book.isMagazine).toList();
    if (section == 'الكتب المدرسية') {
      final level = _selectedSchoolLevel;
      if (level == null) return const [];
      return widget.books.where((book) {
        if (book.isMagazine) return false;
        final text = '${book.category} ${book.title}'.toLowerCase();
        return text.contains(level.toLowerCase());
      }).toList();
    }
    return const [];
  }

  void _selectSection(String section) {
    if (section == 'الجامعي') {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('الجامعي'),
          content: const Text('سيتم إضافة المحتوى لاحقا'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا')),
          ],
        ),
      );
      return;
    }
    setState(() {
      _selectedSection = section;
      _selectedSchoolLevel = null;
    });
  }

  void _selectSchoolLevel(String level) => setState(() => _selectedSchoolLevel = level);

  void _openBook(Book book) {
    if (book.isMagazine) {
      _openMagazine(book);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(book: book)));
  }

  Future<void> _openMagazine(Book book) async {
    String magazineName = book.title.trim();
    if (magazineName.contains(' — العدد')) magazineName = magazineName.split(' — العدد').first.trim();
    if (magazineName.startsWith('مجلة ')) magazineName = magazineName.substring(5).trim();
    try {
      final magazine = await SupabaseService().getMagazineByName(magazineName);
      if (!mounted) return;
      if (magazine == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر العثور على بيانات المجلة.')));
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MagazineScreen(
            magazineId: magazine['id'] as String,
            magazineName: magazine['name'] as String,
            description: magazine['description'] as String?,
            coverUrl: magazine['cover_url'] as String?,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح المجلة. تحقق من اتصال الإنترنت.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: _selectedSection != null
            ? IconButton(
                tooltip: 'الأقسام',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _selectedSection = null;
                  _selectedSchoolLevel = null;
                }),
              )
            : null,
      ),
      body: _selectedSection == null ? _buildSections(isDark) : _buildSectionContent(isDark),
    );
  }

  Widget _buildSections(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        const Text('تصفح حسب القسم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('اختر القسم الذي تريد تصفحه', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 22),
        _SectionCard(icon: Icons.menu_book_rounded, title: 'الكتب', subtitle: 'جميع الكتب المتوفرة في كِتارا', onTap: () => _selectSection('الكتب')),
        _SectionCard(icon: Icons.auto_stories_rounded, title: 'المجلات', subtitle: 'استكشف المجلات والأعداد المتوفرة', onTap: () => _selectSection('المجلات')),
        _SectionCard(icon: Icons.school_rounded, title: 'الكتب المدرسية', subtitle: 'الابتدائي • المتوسط • الثانوي', onTap: () => _selectSection('الكتب المدرسية')),
        _SectionCard(icon: Icons.account_balance_rounded, title: 'الجامعي', subtitle: 'سيتم إضافة المحتوى لاحقا', onTap: () => _selectSection('الجامعي')),
      ],
    );
  }

  Widget _buildSectionContent(bool isDark) {
    if (_selectedSection == 'الكتب المدرسية' && _selectedSchoolLevel == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Text('الكتب المدرسية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _LevelCard(icon: Icons.child_care_rounded, title: 'الطور الابتدائي', onTap: () => _selectSchoolLevel('الابتدائي')),
          _LevelCard(icon: Icons.school_outlined, title: 'الطور المتوسط', onTap: () => _selectSchoolLevel('المتوسط')),
          _LevelCard(icon: Icons.cast_for_education_rounded, title: 'الطور الثانوي', onTap: () => _selectSchoolLevel('الثانوي')),
        ],
      );
    }

    if (_selectedSection == 'الكتب المدرسية' && _selectedSchoolLevel == 'الابتدائي') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Text('الطور الابتدائي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _LevelCard(icon: Icons.looks_one_rounded, title: 'الأولى ابتدائي', onTap: () => _selectSchoolLevel('الأولى ابتدائي')),
          _LevelCard(icon: Icons.looks_two_rounded, title: 'الثانية ابتدائي', onTap: () => _selectSchoolLevel('الثانية ابتدائي')),
          _LevelCard(icon: Icons.looks_3_rounded, title: 'الثالثة ابتدائي', onTap: () => _selectSchoolLevel('الثالثة ابتدائي')),
          _LevelCard(icon: Icons.looks_4_rounded, title: 'الرابعة ابتدائي', onTap: () => _selectSchoolLevel('الرابعة ابتدائي')),
          _LevelCard(icon: Icons.looks_5_rounded, title: 'الخامسة ابتدائي', onTap: () => _selectSchoolLevel('الخامسة ابتدائي')),
        ],
      );
    }

    final books = _sectionBooks;
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_selectedSection == 'المجلات' ? Icons.auto_stories_outlined : Icons.menu_book_outlined, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text('لا توجد محتويات مضافة حاليًا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: SizedBox(
              width: 55,
              height: 75,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(book.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded)),
                          )
                        : const Icon(Icons.menu_book_rounded, size: 40, color: orange),
                  ),
                  if (book.isExclusive)
                    const Positioned(
                      top: -6,
                      right: -6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.author),
            onTap: () => _openBook(book),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(width: 58, height: 58, decoration: BoxDecoration(color: orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: orange, size: 30)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey))])),
              const Icon(Icons.chevron_left_rounded, color: orange),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LevelCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        minVerticalPadding: 14,
        leading: CircleAvatar(backgroundColor: orange.withValues(alpha: 0.12), child: Icon(icon, color: orange)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}
