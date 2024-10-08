import 'package:flutter/services.dart';

class BatteryOptimizationManager {
  static const platform = MethodChannel('battery_optimization');

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      final String result = await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      print('Result: $result');
    } on PlatformException catch (e) {
      print('Failed to exclude from battery optimizations: ${e.message}');
    }
  }
}
