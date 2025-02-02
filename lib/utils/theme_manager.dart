import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _themeKey = 'isDarkMode';

  /// Saves the dark mode state (true = dark, false = light)
  static Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  /// Loads the last saved theme, defaulting to false (light mode)
  static Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
}
