import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';

// Create a Fake controller to capture calls
class FakeWebViewController extends Fake implements InAppWebViewController {
  bool reloadCalled = false;
  String? evaluatedJs;
  InAppWebViewSettings? appliedSettings;

  @override
  Future<void> reload() async {
    reloadCalled = true;
  }

  @override
  Future<dynamic> evaluateJavascript(
      {required String source, ContentWorld? contentWorld}) async {
    evaluatedJs = source;
    return null;
  }

  @override
  Future<void> setSettings({required InAppWebViewSettings settings}) async {
    appliedSettings = settings;
  }
}

void main() {
  group('DesktopModeManager', () {
    test('initial state is mobile', () {
      final manager = DesktopModeManager();
      expect(manager.isDesktopMode, false);
      final settings = manager.getSettings();
      expect(settings.preferredContentMode, UserPreferredContentMode.MOBILE);
      expect(settings.userAgent, isNull);
    });

    test('toggleDesktopMode switches state and updates controller', () async {
      final manager = DesktopModeManager();
      final fakeController = FakeWebViewController();
      manager.setWebViewController(fakeController);

      await manager.toggleDesktopMode();

      expect(manager.isDesktopMode, true);
      expect(fakeController.reloadCalled, true);
      expect(fakeController.evaluatedJs,
          contains('width=1024')); // Desktop viewport
      expect(fakeController.appliedSettings?.userAgent,
          contains('Windows NT 10.0'));
    });

    test('locking to desktop mode persists and applies to new controller',
        () async {
      final manager = DesktopModeManager();
      final controller1 = FakeWebViewController();
      manager.setWebViewController(controller1);

      // Toggle ON
      await manager.toggleDesktopMode();
      expect(manager.isDesktopMode, true);

      // Switch controller (simulating tab switch)
      final controller2 = FakeWebViewController();
      manager.setWebViewController(controller2);

      // Verify settings were applied to controller2 immediately
      expect(controller2.appliedSettings, isNotNull);
      expect(
          controller2.appliedSettings?.userAgent, contains('Windows NT 10.0'));
      // Note: Javascript injection is NOT automatic in setWebViewController, it happens in injectViewportLogic
      expect(controller2.evaluatedJs, isNull);
    });

    test('injectViewportLogic runs JS if enabled', () async {
      final manager = DesktopModeManager();
      final controller = FakeWebViewController();
      manager.setWebViewController(controller);

      // Turn on
      await manager.toggleDesktopMode();

      // Reset capture
      controller.evaluatedJs = null;

      // Inject
      await manager.injectViewportLogic();
      expect(controller.evaluatedJs, contains('viewport'));
    });
  });
}
