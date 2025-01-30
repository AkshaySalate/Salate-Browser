import 'package:flutter/material.dart';
import 'package:salate_browser/pages/home_page.dart'; // Import BrowserHomePage
import 'package:salate_browser/pages/extension_manager.dart'; // Import ExtensionManager

void main() {
  runApp(const SalateBrowser());
}

class SalateBrowser extends StatefulWidget {
  const SalateBrowser({super.key});

  @override
  _SalateBrowserState createState() => _SalateBrowserState();
}

class _SalateBrowserState extends State<SalateBrowser> {
  // Initial theme mode is dark
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
      ),
      themeMode: _themeMode, // Apply theme mode based on the state
      home: BrowserHomePage(onThemeToggle: toggleTheme), // Pass toggle function
    );
  }
}
