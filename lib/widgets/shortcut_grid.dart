import 'package:flutter/material.dart';

class ShortcutGrid extends StatelessWidget {
  final Function(String url) onShortcutSelected;

  const ShortcutGrid({super.key, required this.onShortcutSelected});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shortcuts = [ // Explicitly define types
      {"icon": Icons.mail, "label": "Gmail", "url": "https://mail.google.com/"},
      {"icon": Icons.map, "label": "Maps", "url": "https://maps.google.com/"},
      {"icon": Icons.drive_file_move, "label": "Drive", "url": "https://drive.google.com/"},
      {"icon": Icons.video_library, "label": "YouTube", "url": "https://www.youtube.com/"},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: shortcuts.map((s) {
        return GestureDetector(
          onTap: () => onShortcutSelected(s["url"] as String), // Explicit cast
          child: Column(
            children: [
              Icon(s["icon"] as IconData, size: 40), // Explicit cast
              Text(s["label"] as String), // Explicit cast
            ],
          ),
        );
      }).toList(),
    );
  }
}
