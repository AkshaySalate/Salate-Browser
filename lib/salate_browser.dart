import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const SalateBrowser());
}

class SalateBrowser extends StatelessWidget {
  const SalateBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF121212),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.amber),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white54),
          titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white60),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
      home: const BrowserHomePage(),
    );
  }
}

class BrowserHomePage extends StatefulWidget {
  const BrowserHomePage({super.key});

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class BrowserHomePageState extends State<BrowserHomePage> {
  final List<Map<String, dynamic>> _tabs = [
    {"isHomepage": true, "url": "https://google.com"},
  ];
  final List<String> _history = [];
  int _currentTabIndex = 0;

  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _tabs[_currentTabIndex] = {"isHomepage": true, "url": "https://google.com"};
                });
              },
            ),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search or enter URL',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    suffixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.go,
                  onSubmitted: _handleNavigation,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addNewTab,
              tooltip: 'New Tab',
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tab),
                  onPressed: _showAllTabs,
                  tooltip: 'Show All Tabs',
                ),
                if (_tabs.isNotEmpty)
                  Positioned(
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        '${_tabs.length}',
                        style: TextStyle(color: Theme.of(context).iconTheme.color, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'history') {
                  _showHistory(context);
                } else if (value == 'extensions') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExtensionManager()),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'history',
                  child: Text('History'),
                ),
                PopupMenuItem(
                  value: 'extensions',
                  child: Text('Extensions'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _tabs[_currentTabIndex]["isHomepage"]
          ? BrowserHomepage(onSearch: _handleNavigation)
          : InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(_tabs[_currentTabIndex]["url"] ?? "https://google.com"),
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _webViewController.setOptions(
                  options: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                    ),
                  ),
                );
              },
              onLoadStop: (controller, url) {
                if (url != null && !_history.contains(url.toString())) {
                  setState(() {
                    _history.add(url.toString());
                  });
                }
              },
      ),
    );
  }

  void _handleNavigation(String input) {
    // Ensure input is valid, default to a search query if not a proper URL
    final String validUrl = input.startsWith("http://") || input.startsWith("https://")
        ? input
        : 'https://google.com/search?q=$input';

    // Create a WebUri
    final WebUri uri = WebUri(validUrl);

    setState(() {
      _tabs[_currentTabIndex] = {"isHomepage": false, "url": uri.toString()};
    });

    _webViewController.loadUrl(urlRequest: URLRequest(url: uri));
  }

  void _addNewTab() {
    setState(() {
      _tabs.add({"isHomepage": true, "url": "https://google.com"});
      _currentTabIndex = _tabs.length - 1;
    });
  }

  void _showAllTabs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllTabsPage(
          tabs: _tabs,
          onTabSelected: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            Navigator.pop(context);
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);
              if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.length - 1;
              }
            });
          },
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_history[index]),
            onTap: () {
              Navigator.pop(context);
              _handleNavigation(_history[index]);
            },
          );
        },
      ),
    );
  }
}

class BrowserHomepage extends StatelessWidget {
  final Function(String url) onSearch;

  const BrowserHomepage({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              time,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: "Search or enter URL",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildShortcut(Icons.mail, "Gmail", "https://mail.google.com/"),
              _buildShortcut(Icons.map, "Maps", "https://maps.google.com/"),
              _buildShortcut(Icons.drive_file_move, "Drive", "https://drive.google.com/"),
              _buildShortcut(Icons.video_library, "YouTube", "https://www.youtube.com/"),
            ],
          ),
          const SizedBox(height: 20),
          const Text("To-Do List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Add a task...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () => onSearch(url),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}


class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Here you could load the URL in a WebView (for actual web browsing functionality).
    return Scaffold(
      appBar: AppBar(title: const Text("Chrome Web Store")),
      body: Center(
        child: Text('Redirecting to $url...'),
      ),
    );
  }
}

class ExtensionManager extends StatelessWidget {
  const ExtensionManager({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> extensions = [
      {'name': 'AdBlocker', 'enabled': true},
      {'name': 'Dark Mode', 'enabled': false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Extension Manager')),
      body: ListView.builder(
        itemCount: extensions.length,
        itemBuilder: (context, index) {
          final extension = extensions[index];
          return ListTile(
            title: Text(extension['name']),
            trailing: Switch(
              value: extension['enabled'],
              onChanged: (value) {
                // Toggle enable/disable logic
              },
            ),
          );
        },
      ),
    );
  }
}

class AllTabsPage extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
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
            title: Text(tabs[index]["url"] ?? "Homepage"),
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
}