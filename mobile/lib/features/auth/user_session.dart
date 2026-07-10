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

  static int get profileCompletionPercentage {
    if (current == null) return 0;
    
    int total = 8;
    int filled = 0;
    
    if ((current!['name'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((current!['phone'] ?? '').toString().trim().isNotEmpty) filled++;
    filled++; // blood group always has a value
    if ((current!['dob'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((current!['gender'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((current!['address'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((current!['allergies'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((current!['medical_conditions'] ?? '').toString().trim().isNotEmpty) filled++;
    
    return ((filled / total) * 100).round();
  }
}
