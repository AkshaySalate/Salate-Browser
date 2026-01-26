import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_engine_model.dart';
import '../models/search_category_model.dart';

class SearchPreferenceManager {
  static const String _engineKey = 'selected_search_engine';
  static const String _categoryKey = 'selected_search_category';

  static Future<SearchEngine> loadSearchEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_engineKey);
    if (name != null) {
      return SearchEngine.values.firstWhere(
        (e) => e.name == name,
        orElse: () => SearchEngine.google,
      );
    }
    return SearchEngine.google;
  }

  static Future<void> saveSearchEngine(SearchEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_engineKey, engine.name);
  }

  static Future<SearchCategory> loadSearchCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_categoryKey);
    if (name != null) {
      return SearchCategory.values.firstWhere(
        (e) => e.name == name,
        orElse: () => SearchCategory.web,
      );
    }
    return SearchCategory.web;
  }

  static Future<void> saveSearchCategory(SearchCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryKey, category.name);
  }
}
