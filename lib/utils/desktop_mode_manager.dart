import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DesktopModeManager {
  InAppWebViewController? _webViewController;
  bool _isDesktopMode = false;

  bool get isDesktopMode => _isDesktopMode;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    // Apply current mode to the new controller immediately
    if (_isDesktopMode) {
      _applySettings();
    }
  }

  InAppWebViewSettings getSettings() {
    return InAppWebViewSettings(
      preferredContentMode: _isDesktopMode
          ? UserPreferredContentMode.DESKTOP
          : UserPreferredContentMode.MOBILE,
      useWideViewPort: _isDesktopMode,
      builtInZoomControls: _isDesktopMode,
      displayZoomControls: _isDesktopMode,
      loadWithOverviewMode: _isDesktopMode,
      userAgent: _isDesktopMode
          ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36"
          : null,
    );
  }

  Future<void> setDesktopMode(bool enabled) async {
    _isDesktopMode = enabled;
    if (_webViewController != null) {
      await _applySettings();
      await _injectViewportLogic();
      await _webViewController!.reload();
    }
  }

  Future<void> toggleDesktopMode() async {
    await setDesktopMode(!_isDesktopMode);
  }

  Future<void> _applySettings() async {
    if (_webViewController != null) {
      await _webViewController!.setSettings(settings: getSettings());
    }
  }

  Future<void> injectViewportLogic() async {
    if (_isDesktopMode && _webViewController != null) {
      await _injectViewportLogic();
    }
  }

  Future<void> _injectViewportLogic() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: '''
          var head = document.getElementsByTagName('head')[0];
          var existingMeta = document.querySelector('meta[name="viewport"]');
          if (existingMeta) {
            head.removeChild(existingMeta);
          }
          var meta = document.createElement('meta');
          meta.name = "viewport";
          meta.content = "${_isDesktopMode ? 'width=1024' : 'width=device-width, initial-scale=1.0'}";
          head.appendChild(meta);
        ''',
      );
    }
  }
}
