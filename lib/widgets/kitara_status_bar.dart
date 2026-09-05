import 'package:flutter/material.dart';

import '../services/coins_service.dart';
import '../services/supabase_service.dart';

class KitaraStatusBar extends StatefulWidget {
  final bool exclusiveUnlocked;
  final Future<void> Function(String code) onActivated;

  const KitaraStatusBar({
    super.key,
    required this.exclusiveUnlocked,
    required this.onActivated,
  });

  @override
  State<KitaraStatusBar> createState() => _KitaraStatusBarState();
}

class _KitaraStatusBarState extends State<KitaraStatusBar> {
  int _coins = 0;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    CoinsService.balance.addListener(_onCoinsChanged);
    _loadCoins();
  }

  @override
  void dispose() {
    CoinsService.balance.removeListener(_onCoinsChanged);
    super.dispose();
  }

  void _onCoinsChanged() {
    if (mounted) setState(() => _coins = CoinsService.balance.value);
  }

  Future<void> _loadCoins() async {
    final value = await CoinsService().loadBalance();
    if (mounted) setState(() => _coins = value);
  }

  Future<void> _showCoinsInfo() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('عملات كِتارا'),
        content: Text(
          'عند كل تحميل ناجح تربح عملة واحدة.\n\n'
          'استمر في التحميل واجمع العملات، وعند الوصول إلى العدد المطلوب للمكافأة ستحصل على مكافأة مميزة.\n\n'
          'رصيدك الحالي: $_coins عملة',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  Future<void> _activate() async {
    if (_activating) return;

    final controller = TextEditingController();
    final enteredCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('المحتوى الحصري'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'للوصول إلى المحتوى الحصري والمدفوع أدخل الكود.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'كود التشغيل',
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
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || enteredCode == null || enteredCode.trim().isEmpty) return;

    setState(() => _activating = true);
    try {
      final valid = await SupabaseService().validateKitaraActivationCode(enteredCode.trim());
      if (!mounted) return;

      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كود التشغيل غير صحيح.')),
        );
        return;
      }

      await widget.onActivated(enteredCode.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل المحتوى الحصري.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر التحقق من الكود. تحقق من اتصال الإنترنت وحاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const orange = Color(0xFFF28C28);
    final accent = widget.exclusiveUnlocked ? orange : green;

    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _showCoinsInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.38)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded, size: 19, color: accent),
                  const SizedBox(width: 5),
                  Text('$_coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.exclusiveUnlocked ? null : _activate,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.48)),
              ),
              child: Text(
                widget.exclusiveUnlocked ? 'المحتوى الحصري' : 'النسخة المجانية',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
