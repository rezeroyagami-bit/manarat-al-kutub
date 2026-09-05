import 'package:flutter/material.dart';

import 'supabase_service.dart';

class KitaraRemoteConfig {
  final Map<String, String> values;

  const KitaraRemoteConfig(this.values);

  String _s(String key, String fallback) {
    final value = values[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  bool _b(String key, bool fallback) {
    final value = values[key]?.trim().toLowerCase();
    if (value == 'true' || value == '1' || value == 'yes') return true;
    if (value == 'false' || value == '0' || value == 'no') return false;
    return fallback;
  }

  Color _c(String key, Color fallback) {
    final raw = values[key]?.trim().replaceFirst('#', '');
    if (raw == null || raw.isEmpty) return fallback;
    final parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) return fallback;
    return Color(raw.length <= 6 ? 0xFF000000 | parsed : parsed);
  }

  String get appTitle => _s('app_title', 'KITARA — كِتارا');
  String get brandArabic => _s('brand_arabic', 'كِتارا');
  String get welcomeTitle => _s('welcome_title', 'مرحبًا بك في كِتارا');
  String get welcomeSubtitle => _s('welcome_subtitle', 'اقرأ • استكشف • استمتع');
  String get introTitle => _s('intro_title', 'رحلة الكتاب تبدأ بصفحة');
  String get introSubtitle => _s('intro_subtitle', 'اقرأ • استكشف • استمتع');
  String get searchHint => _s('search_hint', 'ابحث عن كتاب أو مجلة أو مؤلف...');
  String get categoriesTitle => _s('categories_title', 'تصفح حسب القسم');
  String get searchResultsTitle => _s('search_results_title', 'نتائج البحث');
  String get booksTitle => _s('books_title', 'الكتب');
  String get oldMagazinesTitle => _s('old_magazines_title', 'المجلات القديمة');
  String get latestTitle => _s('latest_title', 'أحدث المحتوى');
  String get allCategoryTitle => _s('all_category_title', 'الكل');
  String get navHome => _s('nav_home', 'الرئيسية');
  String get navLibrary => _s('nav_library', 'المكتبة');
  String get navFavorites => _s('nav_favorites', 'المفضلة');
  String get navDownloads => _s('nav_downloads', 'تنزيلاتي');
  String get supportTooltip => _s('support_tooltip', 'الدعم والشكاوى');
  String get aboutTooltip => _s('about_tooltip', 'حول كِتارا');
  String get freeStatusText => _s('free_status_text', 'النسخة المجانية');
  String get exclusiveStatusText => _s('exclusive_status_text', 'المحتوى الحصري');
  String get freeActivationMessage => _s('free_activation_message', 'للوصول إلى المحتوى الحصري والمدفوع أدخل الكود.');
  String get freeEmptyText => _s('empty_books', 'لا توجد كتب مضافة حاليًا.');
  String get magazineEmptyText => _s('empty_magazines', 'لا توجد مجلات مضافة حاليًا.');
  String get noResultsText => _s('no_results', 'لم يتم العثور على محتوى مطابق.');
  String get loadingText => _s('loading_text', 'جاري تجهيز مكتبتك...');
  String get appVersion => _s('app_version_text', '1.0.0');

  bool get showCategories => _b('show_categories', true);
  bool get showBooks => _b('show_books_section', true);
  bool get showOldMagazines => _b('show_old_magazines_section', true);
  bool get showLatest => _b('show_latest_section', true);

  Color get freePrimaryColor => _c('free_primary_color', const Color(0xFF2E7D32));
  Color get exclusivePrimaryColor => _c('exclusive_primary_color', const Color(0xFFF28C28));
  Color get newsColor => _c('news_color', const Color(0xFFC62828));
}

class RemoteConfigStore extends ChangeNotifier {
  RemoteConfigStore._();
  static final RemoteConfigStore instance = RemoteConfigStore._();

  KitaraRemoteConfig _config = const KitaraRemoteConfig({});
  bool _loading = false;

  KitaraRemoteConfig get config => _config;

  Future<void> load({bool supabaseReady = true}) async {
    if (!supabaseReady || _loading) return;
    _loading = true;
    try {
      final values = await SupabaseService().getAppSettings();
      _config = KitaraRemoteConfig(Map<String, String>.from(values));
      notifyListeners();
    } catch (_) {
      // Keep the last known configuration and safe defaults.
    } finally {
      _loading = false;
    }
  }
}
