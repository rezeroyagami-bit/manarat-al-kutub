import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_identity_service.dart';
import 'supabase_service.dart';

class CoinsService {
  static const _balanceKey = 'kitara_coins_balance';
  static final ValueNotifier<int> balance = ValueNotifier<int>(0);

  final SupabaseService _supabase = SupabaseService();

  Future<int> loadBalance() async {
    try {
      final deviceId = await DeviceIdentityService.getId();
      final value = await _supabase.getCoinBalance(deviceId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey, value);
      balance.value = value;
      return value;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_balanceKey) ?? 0;
      balance.value = value;
      return value;
    }
  }

  Future<int?> awardDownloadCoin() async {
    try {
      final deviceId = await DeviceIdentityService.getId();
      final newBalance = await _supabase.awardCoin(deviceId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey, newBalance);
      balance.value = newBalance;
      return newBalance;
    } catch (_) {
      return null;
    }
  }
}
