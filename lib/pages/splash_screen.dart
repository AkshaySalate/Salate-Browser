// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'home_page.dart'; // Make sure this path matches your file

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
  String? splashHtmlPath;

  @override
  void initState() {
    super.initState();
    loadHtml();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
          MaterialPageRoute(
            builder: (context) => BrowserHomePage(
              onThemeToggle: widget.onThemeToggle,
              isDarkMode: widget.isDarkMode,
            ),
          ),
      );
    });
  }

  Future<void> loadHtml() async {
    final byteData = await DefaultAssetBundle.of(context)
        .load('assets/animation/salate_splash.html');
    final buffer = byteData.buffer;
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/salate_splash.html').writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    setState(() {
      splashHtmlPath = file.uri.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: splashHtmlPath == null
          ? const Center(child: CircularProgressIndicator())
          : InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(splashHtmlPath!)),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          disableContextMenu: true,
          javaScriptEnabled: true,
        ),
      ),
    );
  }
}
