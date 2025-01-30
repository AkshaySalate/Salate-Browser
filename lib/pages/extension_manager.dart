import 'package:flutter/material.dart';

class ExtensionManager extends StatelessWidget {
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
                // Toggle enable/disable
              },
            ),
            onTap: () {
              // Navigate to extension settings
            },
          );
        },
      ),
    );
  }
}
