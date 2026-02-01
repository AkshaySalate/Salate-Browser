import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const platform = MethodChannel('com.salate.browser/role');

  Future<void> _setDefaultBrowser() async {
    try {
      await platform.invokeMethod('requestDefaultBrowser');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default browser: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fix: Use current theme state from context, not the stale widget.isDarkMode passed in constructor
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.web, color: textColor),
            title: Text(
              "Set as Default Browser",
              style: TextStyle(color: textColor),
            ),
            subtitle: Text(
              "Make Salate Browser your default web browser",
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
            onTap: _setDefaultBrowser,
          ),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: textColor),
            title: Text(
              "Dark Mode",
              style: TextStyle(color: textColor),
            ),
            value: isDark,
            onChanged: widget.onThemeToggle,
            activeTrackColor: Colors.blue,
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: textColor),
            title: Text(
              "About",
              style: TextStyle(color: textColor),
            ),
            subtitle: Text(
              "Salate Browser v1.0.0",
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
