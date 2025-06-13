// ============================
// all_tabs_page.dart – Enhanced Tab Manager UI
// ============================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salate_browser/models/tab_model.dart';

class AllTabsPage extends StatefulWidget {
  final List<TabModel> tabs;
  final Function(int) onTabSelected;
  final Function(int) onTabRemoved;
  final Function() onAddNewTab;
  final Function(List<TabModel>) onReorderTabs;
  final Function(int) onTogglePin;

  const AllTabsPage({
    required this.tabs,
    required this.onTabSelected,
    required this.onTabRemoved,
    required this.onAddNewTab,
    required this.onReorderTabs,
    required this.onTogglePin,
    super.key,
  });

  @override
  State<AllTabsPage> createState() => _AllTabsPageState();
}

class _AllTabsPageState extends State<AllTabsPage> {
  late List<TabModel> tabs;

  @override
  void initState() {
    super.initState();
    tabs = List.from(widget.tabs);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final TabModel movedTab = tabs.removeAt(oldIndex);
      tabs.insert(newIndex, movedTab);
    });
    widget.onReorderTabs(tabs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Tabs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onAddNewTab,
          )
        ],
      ),
      body: ReorderableListView(
        onReorder: _onReorder,
        children: [
          for (int i = 0; i < tabs.length; i++)
            _buildTabCard(context, tabs[i], i, Key('$i')),
        ],
      ),
    );
  }

  Widget _buildTabCard(BuildContext context, TabModel tab, int index, Key key) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: tab.screenshotBase64 != null
            ? Image.memory(
          base64Decode(tab.screenshotBase64!),
          width: 64,
          height: 48,
          fit: BoxFit.cover,
        )
            : const Icon(Icons.web),
        title: Text(
          tab.title ?? tab.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (tab.group != null) ...[
              const Icon(Icons.folder, size: 14),
              const SizedBox(width: 4),
              Text(tab.group!),
            ],
            if (tab.isPinned) ...[
              const SizedBox(width: 10),
              const Icon(Icons.push_pin, size: 14),
            ]
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () => widget.onTogglePin(index),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => widget.onTabRemoved(index),
            ),
          ],
        ),
        onTap: () => widget.onTabSelected(index),
      ),
    );
  }
}
