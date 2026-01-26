import 'package:flutter_test/flutter_test.dart';
import 'package:salate_browser/models/tab_model.dart';

void main() {
  group('TabModel', () {
    test('serialization includes isDesktopMode', () {
      final tab = TabModel(
        url: 'https://example.com',
        isDesktopMode: true,
        isPinned: true,
      );

      final json = tab.toJson();
      expect(json['isDesktopMode'], true);
      expect(json['isPinned'], true);

      final decoded = TabModel.fromJson(json);
      expect(decoded.isDesktopMode, true);
      expect(decoded.isPinned, true);
    });

    test('default values are correct', () {
      final tab = TabModel(url: 'https://example.com');
      expect(tab.isDesktopMode, false);
      expect(tab.isPinned, false);

      final json = tab.toJson();
      final decoded = TabModel.fromJson(json);
      expect(decoded.isDesktopMode, false);
    });
  });
}
