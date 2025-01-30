import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DesktopModeManager {
  InAppWebViewController? _webViewController;
  bool _isDesktopMode = false;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void toggleDesktopMode() async {
    if (_webViewController != null) {
      _isDesktopMode = !_isDesktopMode;

      await _webViewController!.evaluateJavascript(
        source: '''
          var meta = document.createElement('meta');
          meta.name = "viewport";
          meta.content = "${_isDesktopMode ? 'width=1024' : 'width=device-width, initial-scale=1.0'}";
          document.getElementsByTagName('head')[0].appendChild(meta);
        ''',
      );

      await _webViewController!.setSettings(
        settings: InAppWebViewSettings(
          preferredContentMode: _isDesktopMode
              ? UserPreferredContentMode.DESKTOP
              : UserPreferredContentMode.MOBILE,
          useWideViewPort: _isDesktopMode, // Enables wider layout
          builtInZoomControls: _isDesktopMode, // Enables zoom for desktop view
          displayZoomControls: _isDesktopMode,
          loadWithOverviewMode: _isDesktopMode, // Adjusts layout
          userAgent:
          _isDesktopMode ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36" : null,
        ),
      );

      await _webViewController!.reload(); // Reload the page to apply changes
    }
  }
}
