class TabModel {
  String url;
  bool isHomepage;
  String? faviconUrl;
  String? title; // Optional future use

  TabModel({
    required this.url,
    this.isHomepage = false,
    this.faviconUrl,
    this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isHomepage': isHomepage,
      'faviconUrl': faviconUrl,
      'title': title,
    };
  }

  static TabModel fromJson(Map<String, dynamic> json) {
    return TabModel(
      url: json['url'],
      isHomepage: json['isHomepage'] ?? false,
      faviconUrl: json['faviconUrl'],
      title: json['title'],
    );
  }
}
