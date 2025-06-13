import 'package:flutter/material.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:favicon/favicon.dart';

class AllTabsPage extends StatelessWidget {
  final List<TabModel> tabs;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabRemoved;
  final VoidCallback onAddNewTab;

  const AllTabsPage({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.onTabRemoved,
    required this.onAddNewTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tabs'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: tabs.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            if (index == tabs.length) {
              // + New Tab Card
              return GestureDetector(
                onTap: onAddNewTab,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 36),
                  ),
                ),
              );
            }

            final tab = tabs[index];
            final uri = Uri.tryParse(tab.url);
            final faviconUrl = uri != null ? 'https://${uri.host}/favicon.ico' : null;

            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (faviconUrl != null)
                            CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: NetworkImage(faviconUrl),
                              radius: 16,
                              onBackgroundImageError: (_, __) => const Icon(Icons.language),
                            )
                          else
                            const Icon(Icons.language, size: 24),
                          const SizedBox(height: 12),
                          Text(
                            tab.url,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (tab.isHomepage)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Homepage',
                                style: TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => onTabRemoved(index),
                        child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
