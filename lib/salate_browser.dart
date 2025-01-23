import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logger/logger.dart';


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
        primaryColor: const Color(0xFF1E1E1E), // Dark background color
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Dark background for the whole app
        appBarTheme: const AppBarTheme(
          color: Color(0xFF2C2C2C), // Darker app bar
          iconTheme: IconThemeData(color: Colors.white), // White icons in app bar
        ),
        iconTheme: const IconThemeData(color: Colors.amber), // Amber for icons globally
        textTheme: const TextTheme(
          //bodyText1: TextStyle(color: Colors.white), // White text color
          //bodyText2: TextStyle(color: Colors.grey), // Light grey text for minor elements
          bodyLarge: TextStyle(color: Colors.white), // White text color for large body text
          bodyMedium: TextStyle(color: Colors.grey), // Light grey text for medium elements
          bodySmall: TextStyle(color: Colors.grey), // Light grey text for smaller elements
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
  final TextEditingController _urlController = TextEditingController();
  late WebViewController _webViewController;
  final List<String> _tabs = ["https://google.com"]; // List to track open tabs
  int _currentTabIndex = 0; // Tracks the currently active tab

  @override
  void initState() {
    super.initState();

    final Logger logger = Logger();

    // Initialize WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            logger.d("Loading progress: $progress%");
          },
          onPageStarted: (url) {
            logger.i("Page started loading: $url");
          },
          onPageFinished: (url) {
            // Update the text field with the current URL
            setState(() {
              _urlController.text = url;
            });
            logger.i("Page finished loading: $url");
          },
          onWebResourceError: (error) {
            logger.e("Web resource error: $error");
          },
        ),
      )
      ..loadRequest(Uri.parse(_tabs[_currentTabIndex])); // Load the initial tab
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
                _webViewController.loadRequest(Uri.parse("https://google.com"));
              },
            ),
            Expanded(
              child: TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  hintText: 'Enter URL or search query',
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.withAlpha((0.15 * 255).toInt()), // Light transparent gray
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                    borderSide: BorderSide.none,
                  ),
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
          ],
        ),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }

  void _handleNavigation(String input) {
    if (input.startsWith("http://") || input.startsWith("https://")) {
      // If it's a URL, navigate directly
      _tabs[_currentTabIndex] = input;
      _webViewController.loadRequest(Uri.parse(input));
    } else {
      // If it's a search query, perform a Google search
      String googleSearchUrl = "https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}";
      _tabs[_currentTabIndex] = googleSearchUrl;
      _webViewController.loadRequest(Uri.parse(googleSearchUrl));
    }
  }

  void _addNewTab() {
    setState(() {
      _tabs.add("https://google.com");
      _currentTabIndex = _tabs.length - 1;
    });
    _webViewController.loadRequest(Uri.parse(_tabs[_currentTabIndex]));
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
              _webViewController.loadRequest(Uri.parse(_tabs[_currentTabIndex]));
            });
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);

              // Handle the case where the last tab is removed
              if (_tabs.isEmpty) {
                _tabs.add("https://google.com"); // Add a default tab
              }

              // Adjust the current tab index to stay within bounds
              _currentTabIndex = (_currentTabIndex >= _tabs.length)
                  ? _tabs.length - 1
                  : _currentTabIndex;

              // Load the current tab
              _webViewController.loadRequest(Uri.parse(_tabs[_currentTabIndex]));
            });
          },
        ),
      ),
    );
  }



}

class AllTabsPage extends StatelessWidget {
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabRemoved; // Callback for removing tabs

  const AllTabsPage({super.key,
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
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 9 / 12, // Aspect ratio of each tile
          crossAxisSpacing: 8.0, // Space between columns
          mainAxisSpacing: 8.0, // Space between rows
        ),
        padding: const EdgeInsets.all(8.0),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              GestureDetector(
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
                        child: WebViewWidget(
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadRequest(Uri.parse(tabs[index])),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tabs[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    onTabRemoved(index);
                  },
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.close, size: 16, color: Theme.of(context).iconTheme.color),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
