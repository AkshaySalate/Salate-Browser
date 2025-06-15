// all_tabs_page.dart – Enhanced Tab Manager UI with Tab Groups, Screenshots, Favicons
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
    _sortTabs(); // New function
  }

  void _sortTabs() {
    tabs.sort((a, b) {
      // Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Grouped next
      if ((a.group ?? '') != (b.group ?? '')) {
        return (a.group ?? '').compareTo(b.group ?? '');
      }

      return 0;
    });
  }

  void _assignGroup(int index) {
    TextEditingController controller = TextEditingController();
    tabs.sort((a, b) {
      // Sort by pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by group name (nulls last)
      if (a.group != null && b.group == null) return -1;
      if (a.group == null && b.group != null) return 1;
      return 0;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign Tab Group"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Group name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                tabs[index].group = controller.text;
                _sortTabs(); // Ensure tabs are re-ordered by group
              });
              widget.onReorderTabs(tabs);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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
        leading: tab.faviconUrl != null
            ? Image.network(tab.faviconUrl!, width: 32, height: 32)
            : const Icon(Icons.web),
        title: Text(
          tab.title ?? tab.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tab.group != null && tab.group!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.folder, size: 14),
                  const SizedBox(width: 4),
                  Text(tab.group!),
                ],
              ),
            if (tab.isPinned)
              const Row(
                children: [
                  SizedBox(height: 4),
                  Icon(Icons.push_pin, size: 14),
                  SizedBox(width: 4),
                  Text("Pinned"),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.folder),
              tooltip: 'Set Group',
              onPressed: () => _assignGroup(index),
            ),
            IconButton(
              icon: Icon(
                tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              tooltip: 'Pin/Unpin',
              onPressed: () => widget.onTogglePin(index),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close Tab',
              onPressed: () => widget.onTabRemoved(index),
            ),
          ],
        ),

        onTap: () => widget.onTabSelected(index),
      ),
    );
  }
}
