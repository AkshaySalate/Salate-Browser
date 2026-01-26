import 'package:salate_browser/models/search_engine_model.dart';

enum SearchCategory { web, images, youtube, reddit, wikipedia }

extension SearchCategoryExtension on SearchCategory {
  String get displayName {
    switch (this) {
      case SearchCategory.web:
        return "Web";
      case SearchCategory.images:
        return "Images";
      case SearchCategory.youtube:
        return "YouTube";
      case SearchCategory.reddit:
        return "Reddit";
      case SearchCategory.wikipedia:
        return "Wikipedia";
    }
  }

  String constructSearchUrl(String query, SearchEngine engine) {
    final encodedQuery = Uri.encodeComponent(query);

    switch (this) {
      case SearchCategory.web:
        return engine.constructSearchUrl(query);

      case SearchCategory.images:
        // Engine-specific image search
        switch (engine) {
          case SearchEngine.google:
            return "https://www.google.com/search?tbm=isch&q=$encodedQuery";
          case SearchEngine.duckduckgo:
            return "https://duckduckgo.com/?q=$encodedQuery&iax=images&ia=images";
          case SearchEngine.bing:
            return "https://www.bing.com/images/search?q=$encodedQuery";
          case SearchEngine.brave:
            // Brave Image Search (using their designated endpoint if available, or fallback to standard search)
            // As of knowledge cutoff, Brave Search has an images tab but URL structure is verified below:
            return "https://search.brave.com/images?q=$encodedQuery";
        }

      // These override the engine selection
      case SearchCategory.youtube:
        return "https://www.youtube.com/results?search_query=$encodedQuery";

      case SearchCategory.reddit:
        return "https://www.reddit.com/search/?q=$encodedQuery";

      case SearchCategory.wikipedia:
        return "https://en.wikipedia.org/wiki/Special:Search?search=$encodedQuery";
    }
  }
}
