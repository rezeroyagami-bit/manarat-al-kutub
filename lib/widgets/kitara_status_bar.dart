import 'package:flutter/material.dart';

import '../services/coins_service.dart';
import '../services/supabase_service.dart';

class KitaraStatusBar extends StatefulWidget {
  final bool exclusiveUnlocked;
  final VoidCallback onActivated;

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
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final value = await CoinsService().loadBalance();
    if (mounted) setState(() => _coins = value);
  }

  Future<void> _showCoinsInfo() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('كوينز'),
        content: Text(
          'عند كل تحميل ناجح تربح كوين واحد.\n\n'
          'استمر في التحميل واجمع الكوينز، وعند الوصول إلى العدد المطلوب للمكافأة ستحصل على مكافأة مميزة.\n\n'
          'رصيدك الحالي: $_coins كوين',
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
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('المحتوى الحصري'),
        content: const Text('للوصول إلى الكتب المدفوعة والمحتوى الحصري، أدخل كود التشغيل.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, 'open'),
            child: const Text('إدخال الكود'),
          ),
        ],
      ),
    );
    if (!mounted || code != 'open') return;

    final enteredCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('كود التشغيل'),
        content: TextField(
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
    if (!mounted || enteredCode == null || enteredCode.isEmpty) return;

    setState(() => _activating = true);
    try {
      final valid = await SupabaseService().validateKitaraActivationCode(enteredCode);
      if (!mounted) return;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كود التشغيل غير صحيح.')),
        );
        return;
      }
      widget.onActivated();
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
    const gold = Color(0xFFC89B3C);
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _showCoinsInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold.withValues(alpha: 0.55)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 20, color: gold),
                  const SizedBox(width: 5),
                  Text('$_coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.exclusiveUnlocked ? null : _activate,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.exclusiveUnlocked ? gold.withValues(alpha: 0.18) : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withValues(alpha: 0.65)),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: gold, size: 23),
            ),
          ),
        ],
      ),
    );
  }
}
