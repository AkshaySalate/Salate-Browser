enum SearchEngine { google, duckduckgo, bing, brave }

extension SearchEngineExtension on SearchEngine {
  String get displayName {
    switch (this) {
      case SearchEngine.google:
        return "Google";
      case SearchEngine.duckduckgo:
        return "DuckDuckGo";
      case SearchEngine.bing:
        return "Bing";
      case SearchEngine.brave:
        return "Brave";
    }
  }

  String constructSearchUrl(String query) {
    final encodedQuery = Uri.encodeComponent(query);
    switch (this) {
      case SearchEngine.google:
        return "https://www.google.com/search?q=$encodedQuery";
      case SearchEngine.duckduckgo:
        return "https://duckduckgo.com/?q=$encodedQuery";
      case SearchEngine.bing:
        return "https://www.bing.com/search?q=$encodedQuery";
      case SearchEngine.brave:
        return "https://search.brave.com/search?q=$encodedQuery";
    }
  }
}
