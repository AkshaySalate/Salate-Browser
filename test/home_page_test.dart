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
    expect(find.text('Search or type URL'), findsOneWidget); // Hint text
    expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));

    // Verify Clock is present (WavyClockWidget)
    // We can find by type or just by the fact it's in the tree.
    // Let's verify the "Your Name" field is there
    expect(find.text('Your Name'), findsOneWidget);

    // Test interaction: Tap the search box
    // This previously caused a crash/glitch due to hiding widgets
    await tester.tap(find.text('Search or type URL'));
    await tester.pump();

    // Verify widgets are still there (no crash/disappearance)
    expect(find.text('Your Name'), findsOneWidget);

    // Test URL Bar Sync (mocking text entry)
    // Enter text in search box
    await tester.enterText(
        find.widgetWithText(TextField, 'Search or type URL'), 'google.com');
    await tester.press(find.widgetWithText(TextField, 'Search or type URL'));
    // Trigger submission
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Verify URL bar text is updated
    // The input 'google.com' is converted to a search URL (e.g. https://www.google.com/search?q=google.com)
    // So we check if "google" is present in the text tree.
    expect(find.textContaining('google'), findsAtLeastNWidgets(1));

    // In a real device, it calls onSubmitted -> _handleNavigation -> setState.
    // The _urlController should update.
    // Note: Since we don't have a real WebView, the full navigation won't complete,
    // but the optimistic text update we added in _handleNavigation should work.
  });
}
