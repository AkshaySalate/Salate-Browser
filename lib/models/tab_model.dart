class TabModel {
  String url;
  bool isHomepage;

  TabModel({required this.url, this.isHomepage = false});
}

// models/tab_model.dart
class TabItem {
  final String url;

  TabItem({required this.url});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }

  static TabItem fromJson(Map<String, dynamic> json) {
    return TabItem(
      url: json['url'],
    );
  }
}
