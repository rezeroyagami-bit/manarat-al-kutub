# منارة الكتب — الإصدار 4

تطبيق Flutter عربي RTL لمكتبة كتب ومجلات مرخصة.

## ما الجديد؟
- ربط المكتبة بجدول `public.books` في Supabase.
- الكتب الجديدة التي تضيفها إلى Supabase تظهر في التطبيق عند فتحه من جديد دون تحديث التطبيق.
- استخدام رابط الغلاف المخزن في `cover_url`.
- الإبقاء على ألوان منارة الكتب كما هي.

## إعداد Supabase
1. افتح `lib/services/supabase_config.dart`.
2. اترك `supabaseUrl` كما هو لمشروعك.
3. استبدل `PASTE_YOUR_PUBLISHABLE_KEY_HERE` بمفتاح **Publishable key** من Supabase.
4. لا تضع Service Role / Secret key داخل تطبيق الهاتف.

## ملاحظات
- يجب أن يكون جدول `books` قابلًا للقراءة للـ `anon` مع RLS policy المناسبة.
- يحتاج Android إلى صلاحية INTERNET في `AndroidManifest.xml`.
- إعلانات المكافأة والاشتراك المدفوع ما زالا يحتاجان ربط AdMob وGoogle Play Billing قبل الإطلاق.
- استخدم فقط المحتوى وروابط التحميل التي تملك حق توزيعها.
