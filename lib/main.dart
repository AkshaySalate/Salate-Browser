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
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
      )
          : ThemeData.light(),
      home: BrowserHomePage(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode, // Pass the current theme state
      ),
    );
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }
}