import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/pages/browser_homepage.dart';
import 'package:salate_browser/pages/extension_manager.dart';
import 'package:salate_browser/pages/all_tabs_page.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';

class BrowserHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle; // Accept onThemeToggle
  final bool isDarkMode; // Accept isDarkMode

  const BrowserHomePage({super.key, required this.onThemeToggle, required this.isDarkMode}); // Constructor accepts the onThemeToggle

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class BrowserHomePageState extends State<BrowserHomePage> {
  final List<TabModel> _tabs = [TabModel(url: "https://google.com", isHomepage: true)];
  final List<String> _history = [];
  final DesktopModeManager _desktopModeManager = DesktopModeManager();
  int _currentTabIndex = 0;
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            HomeButton(onPressed: _goToHomePage), // Home button to the left
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
                // Pass the onThemeToggle when navigating to ExtensionManager
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExtensionManager(onThemeToggle: widget.onThemeToggle),
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
        initialUrlRequest: URLRequest(url: WebUri(_tabs[_currentTabIndex].url)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _desktopModeManager.setWebViewController(controller);
        },
        onLoadStop: (controller, url) {
          if (url != null && !_history.contains(url.toString())) {
            setState(() => _history.add(url.toString()));
          }
        },
      ),
    );
  }

  void _handleNavigation(String input) {
    final url = Uri.tryParse(input)?.hasScheme ?? false ? input : 'https://google.com/search?q=$input';
    setState(() => _tabs[_currentTabIndex] = TabModel(url: url, isHomepage: false));
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _addNewTab() => setState(() => _tabs.add(TabModel(url: "https://google.com", isHomepage: true)));

  void _showAllTabs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllTabsPage(
          tabs: _tabs,
          onTabSelected: (index) => setState(() => _currentTabIndex = index),
          onTabRemoved: (index) => setState(() => _tabs.removeAt(index)),
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
          title: Text(_history[index]),
          onTap: () => _handleNavigation(_history[index]),
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
