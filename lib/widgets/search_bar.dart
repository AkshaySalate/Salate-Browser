import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String url) onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onSearch,
      decoration: InputDecoration(
        hintText: "Search or enter URL",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
