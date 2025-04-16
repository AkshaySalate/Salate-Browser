# 🌐 Salate Browser - Project Overview & Developer Guide

Salate Browser is a custom-built web browser made using Flutter. It supports essential browsing features like tabbed browsing, persistent history, dark mode, and desktop mode. This document outlines the current progress and provides a step-by-step developer guide.

---

## ✅ Features Completed

| Feature                         | Status  | File(s) Involved                              |
|--------------------------------|---------|-----------------------------------------------|
| Tabbed Browsing                | ✅ Done | `home_page.dart`, `all_tabs_page.dart`, `tab_model.dart` |
| Persistent Tabs                | ✅ Done | `tab_manager.dart`, `SharedPreferences`       |
| History Tracking               | ✅ Done | `history_model.dart`, `history_manager.dart`  |
| Dark Mode Toggle               | ✅ Done | `extension_manager.dart`, `main.dart`         |
| Dark Mode Persistence          | ✅ Done | `main.dart`, `SharedPreferences`              |
| Desktop Mode Switching         | ✅ Done | `desktop_mode_manager.dart`                   |
| Extension Manager UI           | ✅ Done | `extension_manager.dart`                      |
| Homepage with Shortcuts        | ✅ Done | `browser_homepage.dart`, `shortcut_grid.dart` |
| Search Bar                     | ✅ Done | `browser_homepage.dart`, `search_bar.dart`    |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── models/
│   ├── tab_model.dart
│   ├── history_model.dart
├── pages/
│   ├── home_page.dart
│   ├── browser_homepage.dart
│   ├── webview_page.dart
│   ├── all_tabs_page.dart
│   ├── extension_manager.dart
├── widgets/
│   ├── search_bar.dart
│   ├── shortcut_grid.dart
├── utils/
│   ├── tab_manager.dart
│   ├── history_manager.dart
│   ├── desktop_mode_manager.dart
│   ├── url_helper.dart
```

---

## 🧱 Required Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_inappwebview: ^6.0.0
  shared_preferences: ^2.2.2
```

Then run:
```bash
flutter pub get
```

---

## 🚀 Setup and Running

```bash
git clone <your_repo_url>
cd salate_browser
flutter pub get
flutter run
```

---

## 📘 How Core Features Work

### Theme (Dark Mode)
- Toggle via `ExtensionManager`
- Saved using `SharedPreferences`
- Loaded in `main.dart` on app start

### Tabs
- Created/Switched/Closed in `home_page.dart`
- Saved with `tab_manager.dart` using `SharedPreferences`

### History
- Added on `onLoadStop`
- Stored as list of `HistoryItem`

### Desktop Mode
- Uses `desktop_mode_manager.dart`
- Toggles WebView User-Agent

### Homepage
- Shows current time, search bar, and shortcut grid

---

## 💡 Future To-Do List

| Feature                            | Priority | Notes |
|------------------------------------|----------|-------|
| Bookmarks Manager                  | 🔜 High  | Save/load favorite pages
| Download Manager                   | 🔜 Medium| File download handling
| Incognito Mode                     | 🔜 Medium| No cache/history for private browsing
| Search Engine Selection            | 🔜 Low   | Choose between Google, Bing, DuckDuckGo
| Bookmark Bar UI                    | 🔜 Low   | UI for quick bookmark access
| Ad Blocker Implementation          | 🔜 Medium| Enable actual blocking functionality
| Theme Selector (more than dark/light) | 🔜 Low   | Add multiple color schemes

---

## 🧪 Tips for Contributors

- Use `setState()` properly to trigger UI updates.
- Prefer splitting logic-heavy widgets into smaller classes/files.
- When adding features, keep them modular and place them in `utils/` or `widgets/`.
- Always save critical app state using `SharedPreferences`.

---

## 👨‍💻 Author & Maintainer
Built with ❤️ by Akshay Salate. Contributions welcome!

