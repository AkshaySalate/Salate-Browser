import 'package:flutter/material.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/tabs_manager.dart';

class AllTabsPage extends StatelessWidget {
  final List<TabModel> tabs;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabRemoved;

  const AllTabsPage({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.onTabRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Tabs')),
      body: ListView.builder(
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tabs[index].url), // Displaying the URL of the tab
            onTap: () => onTabSelected(index),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => onTabRemoved(index),
            ),
          );
        },
      ),
    );
  }

  // Saving tabs
  void saveTabs(List<TabItem> tabs) {
    TabsManager.saveTabs(tabs);
  }

// Loading tabs
  void loadTabs() async {
    List<TabItem> tabs = await TabsManager.loadTabs();
    // Restore the tabs in your UI
  }
}

