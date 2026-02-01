import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salate_browser/pages/splash_screen.dart';
import 'package:app_links/app_links.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures async operations can run before runApp()
  bool isDarkMode = await loadTheme(); // Load last saved theme
  runApp(SalateBrowser(isDarkMode: isDarkMode));
}

class SalateBrowser extends StatefulWidget {
  final bool isDarkMode;
  const SalateBrowser({super.key, required this.isDarkMode});

  @override
  State<SalateBrowser> createState() => _SalateBrowserState();
}

class _SalateBrowserState extends State<SalateBrowser> {
  late bool _isDarkMode;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _initialUrl;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode; // Initialize with saved theme state
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        setState(() {
          _initialUrl = initialLink.toString();
        });
      }
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  void _handleIncomingLink(Uri uri) {
    String url = uri.toString();
    // If BrowserHomePage is already active, we want to tell it to open this link.
    // For now, let's store it and we'll use a GlobalKey to notify it.
    _initialUrl = url;
    if (mounted) {
      // We can use a broadcast or GlobalKey. Let's try to pass it down.
      // Re-triggering build to pass new URL if still in splash or just handled by the page.
      setState(() {});
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
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
        initialUrl: _initialUrl,
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
