import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(SalateBrowser());
}

class SalateBrowser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  String homeUrl = "https://google.com"; // Default home page

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
            print("Page finished loading: $url");
          },
          onWebResourceError: (error) {
            print("Web resource error: $error");
          },
        ),
      )
      ..loadRequest(Uri.parse(homeUrl)); // Load the initial URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  hintText: 'Enter URL or search query',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                onSubmitted: (value) => _handleNavigation(value),
              ),
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => _handleNavigation(_urlController.text),
            ),
          ],
        ),
      ),
      body: WebViewWidget(controller: _webViewController), // WebView widget
    );
  }

  void _handleNavigation(String input) {
    if (input.startsWith("http://") || input.startsWith("https://")) {
      // If it's a URL, navigate directly
      _webViewController.loadRequest(Uri.parse(input));
    } else {
      // If it's a search query, perform a Google search
      String googleSearchUrl = "https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}";
      _webViewController.loadRequest(Uri.parse(googleSearchUrl));
    }
  }
}
