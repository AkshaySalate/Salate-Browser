// utils/history_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:salate_browser/models/history_model.dart';

class HistoryManager {
  static const _key = 'browser_history';

  static Future<void> saveHistory(List<HistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(history.map((item) => item.toJson()).toList());
    await prefs.setString(_key, historyJson);
  }

  static Future<List<HistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_key);
    if (historyJson != null) {
      final List<dynamic> decodedJson = jsonDecode(historyJson);
      return decodedJson.map((json) => HistoryItem.fromJson(json)).toList();
    }
    return [];
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
