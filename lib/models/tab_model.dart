// models/tab_model.dart
class TabModel {
  String url;
  bool isHomepage;
  String? faviconUrl;
  String? title;
  bool isPinned;
  String? group;
  String? screenshotBase64;

  TabModel({
    required this.url,
    this.isHomepage = false,
    this.faviconUrl,
    this.title,
    this.isPinned = false,
    this.group,
    this.screenshotBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isHomepage': isHomepage,
      'faviconUrl': faviconUrl,
      'title': title,
      'isPinned': isPinned,
      'group': group,
      'screenshotBase64': screenshotBase64,
    };
  }

  static TabModel fromJson(Map<String, dynamic> json) {
    return TabModel(
      url: json['url'],
      isHomepage: json['isHomepage'] ?? false,
      faviconUrl: json['faviconUrl'],
      title: json['title'],
      isPinned: json['isPinned'] ?? false,
      group: json['group'],
      screenshotBase64: json['screenshotBase64'],
    );
  }
}