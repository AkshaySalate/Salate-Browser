// models/history_model.dart
class HistoryItem {
  final String url;
  final DateTime timestamp;

  HistoryItem({required this.url, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static HistoryItem fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      url: json['url'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
