// models/tab_model.dart
class TabModel {
  String url;
  bool isHomepage;
  String? title;
  String? faviconUrl;
  String? group;
  bool isPinned;
  bool isDesktopMode;

  TabModel({
    required this.url,
    this.isHomepage = false,
    this.title,
    this.faviconUrl,
    this.group,
    this.isPinned = false,
    this.isDesktopMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isHomepage': isHomepage,
      'title': title,
      'faviconUrl': faviconUrl,
      'group': group,
      'isPinned': isPinned,
      'isDesktopMode': isDesktopMode,
    };
  }

  static TabModel fromJson(Map<String, dynamic> json) {
    return TabModel(
      url: json['url'],
      isHomepage: json['isHomepage'] ?? false,
      title: json['title'],
      faviconUrl: json['faviconUrl'],
      group: json['group'],
      isPinned: json['isPinned'] ?? false,
      isDesktopMode: json['isDesktopMode'] ?? false,
    );
  }
}
