import 'package:flutter/material.dart';
import 'package:salate_browser/pages/home_page.dart';

void main() {
  runApp(const SalateBrowser());
}

class SalateBrowser extends StatelessWidget {
  const SalateBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salate Browser',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: const Color(0xFF181818),
      ),
      home: const BrowserHomePage(),
    );
  }
}
