import 'package:flutter/material.dart';
import 'package:salate_browser/pages/home_page.dart'; // Import BrowserHomePage
import 'package:salate_browser/pages/extension_manager.dart'; // Import ExtensionManager
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salate_browser/utils/theme_manager.dart';
import 'package:salate_browser/pages/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures async operations can run before runApp()
  bool isDarkMode = await loadTheme(); // Load last saved theme
  runApp(SalateBrowser(isDarkMode: isDarkMode));
}

class SalateBrowser extends StatefulWidget {
  final bool isDarkMode;
  const SalateBrowser({super.key, required this.isDarkMode});

  @override
  _SalateBrowserState createState() => _SalateBrowserState();
}

class _SalateBrowserState extends State<SalateBrowser> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode; // Initialize with saved theme state
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
    saveTheme(isDarkMode); // Save theme state when toggled
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MySalate',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
      )
          : ThemeData.light(),
      home: SplashScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode, // Pass current theme state
      ),
    );
  }
}

/// Saves the theme state using SharedPreferences
Future<void> saveTheme(bool isDarkMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
}

/// Loads the last saved theme state (defaults to light mode if not set)
Future<bool> loadTheme() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? false; // Default: Light mode
}