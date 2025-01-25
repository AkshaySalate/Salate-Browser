import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
    {"isHomepage": true, "url": ""},
  ];
  List<String> installedExtensions = ["AdBlocker", "Dark Mode", "Language Translator"];
  final Uri chromeWebStoreUrl = Uri.parse('https://chrome.google.com/webstore/category/extensions');
  //final Uri chromeWebStoreUrl = Uri.parse('https://chromewebstore.google.com/');
  final TextEditingController _urlController = TextEditingController();

  late WebViewController _webViewController;
  //final List<String> _tabs = ["https://google.com"]; // List to track open tabs
  int _currentTabIndex = 0; // Tracks the currently active tab

  final List<String> _history = [];
  void _showHistory(BuildContext context) {
    // Ensure history is passed and visible in the modal
    if (_history.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No History'),
          content: const Text('You have not visited any pages yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          itemCount: _history.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_history[index], style: const TextStyle(color: Colors.black),),
              onTap: () {
                // Load the selected URL from history
                Navigator.pop(context);  // Close the history modal
                _handleNavigation(_history[index]);  // Navigate to the selected URL
              },
            );
          },
        ),
      );
    }
  }

  void _showExtensions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extensions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Installed extensions will be listed here.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                    chromeWebStoreUrl,
                    //mode: LaunchMode.externalApplication,
                    mode: LaunchMode.inAppWebView,
                  )) {
                    throw Exception('Could not launch $chromeWebStoreUrl');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Add Extension'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              if (!_history.contains(url) && url.isNotEmpty) {
                _history.add(url); // Add unique, non-empty URLs to the history
              }
            });
          },
        ),
      );
      //..loadRequest(Uri.parse(_tabs[_currentTabIndex])); // Load the initial tab
      // Load the initial tab's URL
      //final String initialUrl = _tabs[_currentTabIndex]["url"] ?? "https://google.com"; // Default to Google if no URL
      //_webViewController.loadRequest(Uri.parse(initialUrl));
  }

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
                  _tabs[_currentTabIndex] = {"isHomepage": true, "url": ""};
                });
              },
            ),
            Expanded(
              child: Container(
                //padding: const EdgeInsets.symmetric(horizontal: 10), // Horizontal padding for width
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.15 * 255).toInt()), // Grey background
                  borderRadius: BorderRadius.circular(12), // Rounded corners for the box
                ),
                child: TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: 'Search or enter URL',
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // This is for the text inside the box
                    border: InputBorder.none, // Remove the border since we are using the container's decoration
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _handleNavigation(_urlController.text),
                    ),
                  ),
                  onSubmitted: (value) => _handleNavigation(value),
                  onTap: () {
                    // Select all text in the TextField when tapped
                    _urlController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _urlController.text.length,
                    );
                  },
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
                    //right: 8,
                    //top: 8,
                    child: CircleAvatar(
                      radius: 10,
                      //backgroundColor: Theme.of(context).iconTheme.color,
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
                  _showExtensions(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'history',
                  child: Text('History'),
                ),
                const PopupMenuItem(
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
          : WebViewWidget(controller: _webViewController),
    );
  }

  void _handleNavigation(String input) {
    if (input.startsWith("http://") || input.startsWith("https://")) {
      setState(() {
        _tabs[_currentTabIndex] = {"isHomepage": false, "url": input};
      });
      _webViewController.loadRequest(Uri.parse(input));

      if (!_history.contains(input) && input.isNotEmpty) {
        setState(() {
          _history.add(input); // Add to history if unique and non-empty
        });
      }
    } else {
      String searchUrl = "https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}";
      setState(() {
        _tabs[_currentTabIndex] = {"isHomepage": false, "url": searchUrl};
      });
      _webViewController.loadRequest(Uri.parse(searchUrl));

      if (!_history.contains(searchUrl) && searchUrl.isNotEmpty) {
        setState(() {
          _history.add(searchUrl); // Add to history if unique and non-empty
        });
      }
    }
  }

  void _addNewTab() {
    setState(() {
      _tabs.add({"isHomepage": true, "url": ""});
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
              final String url = _tabs[_currentTabIndex]["url"] ?? "https://google.com";
              _webViewController.loadRequest(Uri.parse(url));
            });
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);

              // Ensure there is always at least one tab
              if (_tabs.isEmpty) {
                _tabs.add({"isHomepage": true, "url": "https://google.com"}); // Default tab
                _currentTabIndex = 0;
              } else {
                // Adjust the current tab index if necessary
                if (_currentTabIndex >= _tabs.length) {
                  _currentTabIndex = _tabs.length - 1;
                }
              }

              // Reload the current tab after removal
              final String url = _tabs[_currentTabIndex]["url"] ?? "https://google.com";
              _webViewController.loadRequest(Uri.parse(url));
            });
          },
        ),
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
      appBar: AppBar(title: const Text("All Tabs")),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 12,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.all(8.0),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(tabs[index]["url"] ?? index.toString()),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              onTabRemoved(index);
            },
            child: GestureDetector(
              onTap: () {
                onTabSelected(index);
                Navigator.pop(context);
              },
              child: Card(
                elevation: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: tabs[index]["isHomepage"]
                          ? const Center(child: Text("Homepage"))
                          : WebViewWidget(
                        controller: WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..loadRequest(Uri.parse(tabs[index]["url"] ?? "https://google.com")),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tabs[index]["url"] ?? "Homepage",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
