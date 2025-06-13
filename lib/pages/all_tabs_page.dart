import 'package:flutter/material.dart';
import '../models/tab_model.dart';

class AllTabsPage extends StatelessWidget {
  final List<TabModel> tabs;
  final Function(int) onTabSelected;
  final Function(int) onTabRemoved;
  final VoidCallback onAddNewTab;

  const AllTabsPage({
    required this.tabs,
    required this.onTabSelected,
    required this.onTabRemoved,
    required this.onAddNewTab,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Tabs"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.background,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tabs.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3 / 2,
        ),
        itemBuilder: (context, index) {
          if (index == tabs.length) {
            return _buildAddTabCard(context);
          } else {
            final tab = tabs[index];
            return _buildTabCard(context, tab, index);
          }
        },
      ),
    );
  }

  Widget _buildTabCard(BuildContext context, TabModel tab, int index) {
    final theme = Theme.of(context);
    final bgColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (tab.faviconUrl != null)
                      Image.network(
                        tab.faviconUrl!,
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 20),
                      )
                    else
                      const Icon(Icons.language, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tab.title ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Uri.tryParse(tab.url)?.host ?? tab.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => onTabRemoved(index),
              child: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTabCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onAddNewTab,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primary.withOpacity(0.1),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 36),
        ),
      ),
    );
  }
}
