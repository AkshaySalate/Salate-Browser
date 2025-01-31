import 'package:flutter/material.dart';

class ExtensionManager extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const ExtensionManager({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  _ExtensionManagerState createState() => _ExtensionManagerState();
}

class _ExtensionManagerState extends State<ExtensionManager> {
  final List<Map<String, dynamic>> extensions = [
    {'name': 'AdBlocker', 'enabled': true, 'version': '1.0'},
    {'name': 'Dark Mode', 'enabled': false, 'version': '1.2'},
  ];

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Ensure the toggle reflects the correct dark mode state
    _isDarkMode = widget.isDarkMode; // Initialize with the passed value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extension Manager')),
      body: ListView.builder(
        itemCount: extensions.length,
        itemBuilder: (context, index) {
          final extension = extensions[index];

          return ListTile(
            leading: Icon(Icons.extension),
            title: Text(extension['name']),
            subtitle: Text('Version: ${extension['version']}'),
            trailing: extension['name'] == 'Dark Mode'
                ? Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  widget.onThemeToggle(value); // Notify parent widget about the theme change
                });
              },
            )
                : null, // Show the Switch only for Dark Mode
          );
        },
      ),
    );
  }
}
