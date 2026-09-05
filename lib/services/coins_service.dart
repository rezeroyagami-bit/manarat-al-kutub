import 'package:shared_preferences/shared_preferences.dart';

import 'device_identity_service.dart';
import 'supabase_service.dart';

class CoinsService {
  static const _balanceKey = 'kitara_coins_balance';
  final SupabaseService _supabase = SupabaseService();

  Future<int> loadBalance() async {
    try {
      final deviceId = await DeviceIdentityService.getId();
      final balance = await _supabase.getCoinBalance(deviceId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey, balance);
      return balance;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_balanceKey) ?? 0;
    }
  }

  Future<int?> awardDownloadCoin() async {
    try {
      final deviceId = await DeviceIdentityService.getId();
      final balance = await _supabase.awardCoin(deviceId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey, balance);
      return balance;
    } catch (_) {
      return null;
    }
  }
}
