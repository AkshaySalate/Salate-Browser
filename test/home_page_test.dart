import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salate_browser/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Method Channel for Default Browser
  const MethodChannel channel = MethodChannel('com.salate.browser/role');

  setUp(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Mock MethodChannel calls to return null (success)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('BrowserHomePage renders correctly without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // wrapping in MaterialApp as BrowserHomePage needs it
    await tester.pumpWidget(
      MaterialApp(
        home: BrowserHomePage(
          isDarkMode: false,
          onThemeToggle: (val) {},
        ),
      ),
    );

    // Initial pump might start async tasks (timers, looking up prefs)
    // We use pump() instead of pumpAndSettle because there are infinite animations (VideoPlayer, Clock)
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Wait for initial delays

    // Verify vital UI components are present
    expect(find.byType(TextField),
        findsAtLeastNWidgets(2)); // Name input and Search input
    expect(find.text('Search or enter URL'), findsOneWidget); // Hint text
    expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));

    // Verify Clock is present (WavyClockWidget)
    // We can find by type or just by the fact it's in the tree.
    // Let's verify the "Your Name" field is there
    expect(find.text('Your Name'), findsOneWidget);

    // Test interaction: Tap the search box
    // This previously caused a crash/glitch due to hiding widgets
    // verify tap works without crashing
    await tester.tap(find.text('Search or enter URL'), warnIfMissed: false);
    await tester.pump();

    // Verify widgets are still there (no crash/disappearance)
    expect(find.text('Your Name'), findsOneWidget);

    // Skip full navigation test as it instantiates WebView which fails in widget test without complex mocks.
  });
}
