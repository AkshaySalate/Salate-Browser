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
          return ListTile(
            leading: Icon(Icons.extension),
            title: Text(extension['name']),
            subtitle: Text('Version: ${extension['version']}'),
            trailing: Switch(
              value: extension['enabled'],
              onChanged: (value) {
                setState(() {
                  extension['enabled'] = value;

                  // If Dark Mode is toggled, apply the theme change
                  if (extension['name'] == 'Dark Mode') {
                    widget.onThemeToggle(value);
                  }
                });
              },
            ),
            onTap: () {
              // Navigate to extension settings (if you want to implement it later)
            },
          );
        },
      ),
    );
  }
}
