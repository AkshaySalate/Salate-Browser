// utils/tabs_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salate_browser/models/tab_model.dart';

class TabsManager {
  static const _key = 'browser_tabs';

  static Future<void> saveTabs(List<TabModel> tabs) async {
    final prefs = await SharedPreferences.getInstance();
    final tabsJson = jsonEncode(tabs.map((tab) => tab.toJson()).toList());
    await prefs.setString(_key, tabsJson);
  }

  static Future<List<TabModel>> loadTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final tabsJson = prefs.getString(_key);
    if (tabsJson != null) {
      final List<dynamic> decodedJson = jsonDecode(tabsJson);
      return decodedJson.map((json) => TabModel.fromJson(json)).toList();
    }
    return [];
  }
}