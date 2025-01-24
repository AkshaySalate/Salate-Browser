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
        primaryColor: const Color(0xFF212121), // Dark background color
        scaffoldBackgroundColor: const Color(0xFF181818), // Dark background for the whole app
        appBarTheme: const AppBarTheme(
          color: Color(0xFF121212), // Darker app bar
          iconTheme: IconThemeData(color: Colors.white), // White icons in app bar
        ),
        iconTheme: const IconThemeData(color: Colors.amber), // Amber for icons globally
        textTheme: const TextTheme(
          //bodyText1: TextStyle(color: Colors.white), // White text color
          //bodyText2: TextStyle(color: Colors.grey), // Light grey text for minor elements
          bodyLarge: TextStyle(color: Colors.white), // White text color for large body text
          bodyMedium: TextStyle(color: Colors.white70), // Light grey text for medium elements
          bodySmall: TextStyle(color: Colors.white54), // Light grey text for smaller elements
          titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500), // Title style
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF333333), // Slightly lighter background for text fields
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
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blueAccent, // Blue buttons for interaction
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        cardTheme: CardTheme(
          elevation: 5, // Elevation for cards to give a floating effect
          color: const Color(0xFF2C2C2C), // Slightly lighter card color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF2C2C2C),
          selectedColor: Colors.blueAccent,
          labelStyle: TextStyle(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent, // Floating action button color
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.blueAccent, // SnackBar background
          contentTextStyle: TextStyle(color: Colors.white),
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
              title: Text(_history[index], style: const TextStyle(color: Colors.white),),
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
              if (!_history.contains(url) && url.isNotEmpty) {
                  _history.add(url); //only add unique, non-empty urls
                  logger.i("history added: $url");
              }
            });
            // Add to history if not already present
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
                    hintText: 'Enter URL or search query',
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
                if (value == 'history') _showHistory(context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'history',
                  child: Text('History'),
                ),
              ]
            )
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

              // Ensure there is always at least one tab
              if (_tabs.isEmpty) {
                _tabs.add("https://google.com"); // Default tab
                _currentTabIndex = 0;
              } else {
                // Adjust the current tab index if necessary
                if (_currentTabIndex >= _tabs.length) {
                  _currentTabIndex = _tabs.length - 1;
                }
              }

              // Reload the current tab after removal
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
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 9 / 12, // Aspect ratio of each tile
          crossAxisSpacing: 8.0, // Space between columns
          mainAxisSpacing: 8.0, // Space between rows
        ),
        padding: const EdgeInsets.all(8.0),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(tabs[index]), // Unique key for each tab
            direction: DismissDirection.horizontal, // Allow swipe left or right
            onDismissed: (direction) {
              // Immediately remove the tab and update state
              onTabRemoved(index);
            },
            confirmDismiss: (direction) async {
              //confirm the dismissal before proceeding
              await Future.delayed(const Duration(milliseconds: 300));
              return true;
            },
            background: Container(
              color: Colors.red.withAlpha((0.8 * 255).toInt()), // Background when swiping
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red.withAlpha((0.8 * 255).toInt()), // Background for swipe in opposite direction
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () {
                onTabSelected(index);
                Navigator.pop(context); // Go back to the previous screen
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
          );
        },
      ),
    );
  }
}
