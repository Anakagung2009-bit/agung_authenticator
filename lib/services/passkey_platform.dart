import 'package:flutter/services.dart';

class PasskeyPlatform {
  static const MethodChannel _channel = MethodChannel('com.example.agung_auth/passkey');

  static Future<String> startPasskeyLogin(String fidoData) async {
    try {
      final result = await _channel.invokeMethod('startPasskeyLogin', {'fidoData': fidoData});
      return result as String;
    } catch (e) {
      throw Exception('Failed to start passkey login: $e');
    }
  }
}
