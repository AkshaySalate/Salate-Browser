import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/pages/browser_homepage.dart';
import 'package:salate_browser/pages/extension_manager.dart';
import 'package:salate_browser/utils/tabs_manager.dart';
import 'package:salate_browser/pages/all_tabs_page.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';

class BrowserHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const BrowserHomePage({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class BrowserHomePageState extends State<BrowserHomePage> {
  final List<TabModel> _tabs = [TabModel(url: "https://google.com", isHomepage: true)];
  final List<HistoryItem> _history = [];
  final DesktopModeManager _desktopModeManager = DesktopModeManager();
  int _currentTabIndex = 0;
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTabs();
  }

  void _loadHistory() async {
    _history.addAll(await HistoryManager.loadHistory());
    setState(() {});
  }

  void _loadTabs() async {
    List<TabItem> savedTabs = await TabsManager.loadTabs();
    if (savedTabs.isNotEmpty) {
      setState(() {
        _tabs.clear(); // Clear existing tabs before loading
        _tabs.addAll(savedTabs.map((tab) => TabModel(url: tab.url)));
        _currentTabIndex = 0; // Ensure it starts at the first tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            HomeButton(onPressed: _goToHomePage),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search or enter URL',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: _handleNavigation,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewTab),
          IconButton(icon: const Icon(Icons.tab), onPressed: _showAllTabs),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'history') _showHistory();
              if (value == 'extensions') {
                // Pass the onThemeToggle and isDarkMode when navigating to ExtensionManager
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExtensionManager(
                      onThemeToggle: widget.onThemeToggle,
                      isDarkMode: widget.isDarkMode, // Pass the current theme state
                    ),
                  ),
                );
              }
              if (value == 'desktop_mode') {
                _toggleDesktopMode();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'history', child: Text('History')),
              PopupMenuItem(value: 'extensions', child: Text('Extensions')),
              PopupMenuItem(value: 'desktop_mode', child: Text('Desktop Mode')),
            ],
          ),
        ],
      ),
      body: _tabs[_currentTabIndex].isHomepage
          ? BrowserHomepage(onSearch: _handleNavigation)
          : InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(_tabs[_currentTabIndex].url))),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _desktopModeManager.setWebViewController(controller);
        },
          onLoadStop: (controller, url) {
            if (url != null && !_history.any((item) => item.url == url.toString())) {
              final historyItem = HistoryItem(url: url.toString(), timestamp: DateTime.now());
              setState(() => _history.add(historyItem));
              HistoryManager.saveHistory(_history);
            }
          }
      ),
    );
  }

  void _handleNavigation(String input) {
    final url = Uri.tryParse(input)?.hasScheme ?? false ? input : 'https://google.com/search?q=$input';
    setState(() => _tabs[_currentTabIndex] = TabModel(url: url, isHomepage: false));
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri.uri(Uri.parse(url))));
    TabsManager.saveTabs(_tabs.cast<TabItem>());  // Save tabs whenever they are modified
    HistoryManager.saveHistory(_history);
  }

  void _addNewTab() {
    setState(() {
      _tabs.add(TabModel(url: "https://google.com", isHomepage: true));
      _currentTabIndex = _tabs.length - 1;  // Switch to the newly added tab
    });
    TabsManager.saveTabs(_tabs.map((tab) => TabItem(url: tab.url)).toList());
  }


  void _showAllTabs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllTabsPage(
          tabs: _tabs,
          onTabSelected: (index) {
            setState(() => _currentTabIndex = index);
            Navigator.pop(context);
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);
              if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : 0;
              }
            });
            TabsManager.saveTabs(_tabs.map((tab) => TabItem(url: tab.url)).toList()); // Save updated tabs
          },
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: _history.length,
        itemBuilder: (_, index) => ListTile(
          title: Text(_history[index].url),
          onTap: () => _handleNavigation(_history[index].url),
        ),
      ),
    );
  }

  void _goToHomePage() {
    setState(() {
      _tabs[_currentTabIndex] = TabModel(url: "https://google.com", isHomepage: true);
    });
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri("https://google.com")));
  }

  void _toggleDesktopMode() {
    setState(() {
      _desktopModeManager.toggleDesktopMode();
    });
  }
}

class HomeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: onPressed,
    );
  }
}
