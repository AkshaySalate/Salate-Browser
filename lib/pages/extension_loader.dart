import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class ExtensionLoader extends StatefulWidget {
  final WebViewController controller;

  const ExtensionLoader({super.key, required this.controller});

  @override
  _ExtensionLoaderState createState() => _ExtensionLoaderState();
}

class _ExtensionLoaderState extends State<ExtensionLoader> {
  List<Map<String, dynamic>> extensions = [];

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  Future<void> _loadExtensions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedExtensions = prefs.getString('extensions');

    if (storedExtensions != null) {
      setState(() {
        extensions = List<Map<String, dynamic>>.from(jsonDecode(storedExtensions));
      });
    }
  }

  Future<void> _toggleExtension(int index, bool value) async {
    setState(() {
      extensions[index]['enabled'] = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extensions', jsonEncode(extensions));
  }

  Future<void> _addExtension() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController scriptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Extension'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Extension Name')),
            TextField(controller: scriptController, decoration: InputDecoration(labelText: 'JavaScript Code'), maxLines: 5),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newExtension = {
                'name': nameController.text,
                'script': scriptController.text,
                'enabled': true
              };
              setState(() {
                extensions.add(newExtension);
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('extensions', jsonEncode(extensions));
              Navigator.pop(context);
            },
            child: Text('Add'),
          )
        ],
      ),
    );
  }

  void _injectExtensions() {
    for (var ext in extensions) {
      if (ext['enabled'] == true) {
        widget.controller.runJavaScript(ext['script']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extension Loader'), actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: _addExtension,
        )
      ]),
      body: ListView.builder(
        itemCount: extensions.length,
        itemBuilder: (context, index) {
          final extension = extensions[index];
          return ListTile(
            title: Text(extension['name']),
            subtitle: Text(extension['enabled'] ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: extension['enabled'],
              onChanged: (value) => _toggleExtension(index, value),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.play_arrow),
        onPressed: _injectExtensions,
      ),
    );
  }
}
