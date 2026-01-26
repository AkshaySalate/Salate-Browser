import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryManager', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('addHistoryItem appends items correctly', () async {
      final item1 =
          HistoryItem(url: 'https://google.com', timestamp: DateTime.now());
      final item2 =
          HistoryItem(url: 'https://github.com', timestamp: DateTime.now());

      await HistoryManager.addHistoryItem(item1);
      var history = await HistoryManager.loadHistory();
      expect(history.length, 1);
      expect(history.first.url, 'https://google.com');

      await HistoryManager.addHistoryItem(item2);
      history = await HistoryManager.loadHistory();
      expect(history.length, 2);
      expect(history[1].url, 'https://github.com');
    });

    test('saveHistory overwrites correctly', () async {
      final item1 =
          HistoryItem(url: 'https://test.com', timestamp: DateTime.now());
      await HistoryManager.saveHistory([item1]);

      var history = await HistoryManager.loadHistory();
      expect(history.length, 1);

      final item2 =
          HistoryItem(url: 'https://overwrite.com', timestamp: DateTime.now());
      await HistoryManager.saveHistory([item2]);

      history = await HistoryManager.loadHistory();
      expect(history.length, 1);
      expect(history.first.url, 'https://overwrite.com');
    });
  });
}
