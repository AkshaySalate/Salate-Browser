// pages/webview_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/utils/tabs_manager.dart';
import 'package:salate_browser/models/history_model.dart';

class WebViewPage extends StatefulWidget {
  final TabModel tab;
  final List<TabModel> allTabs;

  const WebViewPage({super.key, required this.tab, required this.allTabs});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController _webViewController;
  final List<HistoryItem> history = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tab.title ?? 'WebView Page'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(Uri.parse(widget.tab.url) as String)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStop: (controller, url) async {
          if (url != null) {
            final historyItem = HistoryItem(
              url: url.toString(),
              timestamp: DateTime.now(),
            );
            setState(() => history.add(historyItem));
            HistoryManager.saveHistory(history);

            // Fetch metadata
            await _updateTabMetadata(url.toString());
          }
        },
      ),
    );
  }

  Future<void> _updateTabMetadata(String currentUrl) async {
    try {
      String? pageTitle = await _webViewController.getTitle();

      String domain = Uri.parse(currentUrl).host;
      String faviconUrl = 'https://www.google.com/s2/favicons?sz=64&domain_url=https://$domain';
      debugPrint("Favicon URL: $faviconUrl");

      setState(() {
        widget.tab.title = pageTitle ?? currentUrl;
        widget.tab.faviconUrl = faviconUrl;
        widget.tab.url = currentUrl;
      });

      await TabsManager.saveTabs(widget.allTabs);
    } catch (e, st) {
      debugPrint("Error updating tab metadata: $e\n$st");
    }
  }
}
