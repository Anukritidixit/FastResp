import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static Map<String, dynamic>? current;

  static Future<void> save(Map<String, dynamic> user) async {
    current = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resqlink_user_session', jsonEncode(user));
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('resqlink_user_session');
    if (jsonStr != null) {
      current = jsonDecode(jsonStr);
    }
  }

  static Future<void> clear() async {
    current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resqlink_user_session');
  }
}
