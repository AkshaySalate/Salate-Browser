import 'package:flutter/material.dart';
import 'package:salate_browser/widgets/search_bar.dart';
import 'package:salate_browser/widgets/shortcut_grid.dart';

class BrowserHomepage extends StatelessWidget {
  final Function(String url) onSearch;

  const BrowserHomepage({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SearchBarWidget(onSearch: onSearch),
        const SizedBox(height: 20),
        ShortcutGrid(onShortcutSelected: onSearch),
      ],
    );
  }
}
