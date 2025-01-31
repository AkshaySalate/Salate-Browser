// pages/webview_page.dart
import 'package:flutter/material.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final List<HistoryItem> history = [];
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView Page'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri("https://google.com" as Uri)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStop: (controller, url) {
          if (url != null) {
            final historyItem = HistoryItem(url: url.toString(), timestamp: DateTime.now());
            setState(() => history.add(historyItem));
            HistoryManager.saveHistory(history);
          }
        },
      ),
    );
  }
}
