import 'package:device_info_plus/device_info_plus.dart';

class DeviceIdentityService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getId() async {
    try {
      final info = await _deviceInfo.androidInfo;
      final id = info.id.trim();
      if (id.isNotEmpty) return id;
    } catch (_) {}

    return 'kitara-${DateTime.now().millisecondsSinceEpoch}';
  }
}
