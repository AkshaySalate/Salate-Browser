import 'package:flutter/material.dart';

class ExtensionManager extends StatefulWidget {
  final Function(bool) onThemeToggle;

  const ExtensionManager({super.key, required this.onThemeToggle});

  @override
  _ExtensionManagerState createState() => _ExtensionManagerState();
}

class _ExtensionManagerState extends State<ExtensionManager> {
  final List<Map<String, dynamic>> extensions = [
    {'name': 'AdBlocker', 'enabled': true, 'version': '1.0'},
    {'name': 'Dark Mode', 'enabled': false, 'version': '1.2'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extension Manager')),
      body: ListView.builder(
        itemCount: extensions.length,
        itemBuilder: (context, index) {
          final extension = extensions[index];

          // Check if the extension is 'Dark Mode'
          bool isDarkMode = extension['name'] == 'Dark Mode' && extension['enabled'];

          return ListTile(
            leading: Icon(Icons.extension),
            title: Text(extension['name']),
            subtitle: Text('Version: ${extension['version']}'),
            trailing: extension['name'] == 'Dark Mode'
                ? Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  extension['enabled'] = value;

                  // If Dark Mode is toggled, apply the theme change
                  widget.onThemeToggle(value);
                });
              },
            )
                : null, // Show the Switch only for Dark Mode
            onTap: () {
              // Navigate to extension settings (if you want to implement it later)
            },
          );
        },
      ),
    );
  }
}
