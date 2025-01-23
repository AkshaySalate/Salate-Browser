import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(SalateBrowser());
}

class SalateBrowser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1E1E1E), // Dark background color
        scaffoldBackgroundColor: Color(0xFF1E1E1E), // Dark background for the whole app
        appBarTheme: AppBarTheme(
          color: Color(0xFF2C2C2C), // Darker app bar
          iconTheme: IconThemeData(color: Colors.white), // White icons in app bar
        ),
        iconTheme: IconThemeData(color: Colors.amber), // Amber for icons globally
        textTheme: TextTheme(
          //bodyText1: TextStyle(color: Colors.white), // White text color
          //bodyText2: TextStyle(color: Colors.grey), // Light grey text for minor elements
          bodyLarge: TextStyle(color: Colors.white), // White text color for large body text
          bodyMedium: TextStyle(color: Colors.grey), // Light grey text for medium elements
          bodySmall: TextStyle(color: Colors.grey), // Light grey text for smaller elements
        ),
      ),
      home: BrowserHomePage(),
    );
  }
}

class BrowserHomePage extends StatefulWidget {
  @override
  _BrowserHomePageState createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  final TextEditingController _urlController = TextEditingController();
  late WebViewController _webViewController;
  List<String> _tabs = ["https://google.com"]; // List to track open tabs
  int _currentTabIndex = 0; // Tracks the currently active tab

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            print("Loading progress: $progress%");
          },
          onPageStarted: (url) {
            print("Page started loading: $url");
          },
          onPageFinished: (url) {
            // Update the text field with the current URL
            setState(() {
              _urlController.text = url;
            });
            print("Page finished loading: $url");
          },
          onWebResourceError: (error) {
            print("Web resource error: $error");
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
              icon: Icon(Icons.home),
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
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.15), // Light transparent gray
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
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
              icon: Icon(Icons.add),
              onPressed: _addNewTab,
              tooltip: 'New Tab',
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.tab),
                  onPressed: _showAllTabs,
                  tooltip: 'Show All Tabs',
                ),
                if (_tabs.length > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${_tabs.length}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
        ),
      ),
    );
  }
}

class AllTabsPage extends StatelessWidget {
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  AllTabsPage({required this.tabs, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Tabs")),
      body: ListView.builder(
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.web),
            title: Text(
              tabs[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              onTabSelected(index);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
