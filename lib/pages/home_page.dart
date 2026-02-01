import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/pages/extension_manager.dart';
import 'package:salate_browser/utils/tabs_manager.dart';
import 'package:salate_browser/pages/all_tabs_page.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';
import 'package:salate_browser/models/search_engine_model.dart';
import 'package:salate_browser/models/search_category_model.dart';
import 'package:salate_browser/utils/search_engine_manager.dart';
import 'package:salate_browser/utils/weather_service.dart';
import 'package:salate_browser/widgets/wavy_clock_widget.dart';
import 'package:salate_browser/pages/settings_page.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:salate_browser/pages/file_viewers.dart';
import 'package:app_links/app_links.dart';

class BrowserHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;
  final String? initialUrl;

  const BrowserHomePage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    this.initialUrl,
  });

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class BrowserHomePageState extends State<BrowserHomePage> {
  late double screenWidth;
  late double screenHeight;
  final List<TabModel> _tabs = [TabModel(url: "about:blank", isHomepage: true)];
  final List<HistoryItem> _history = [];
  final DesktopModeManager _desktopModeManager = DesktopModeManager();
  int _currentTabIndex = 0;

  // [FIX] Independent Controllers & State
  final Map<int, InAppWebViewController> _controllers = {};

  // [FIX] URL Bar Interaction Logic
  final FocusNode _urlFocusNode = FocusNode();
  bool _isUrlReadOnly = true;

  String? _userName;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  double? _humidity;
  double? _temperature;
  String? _weatherIconUrl;
  String? _locationName;
  String _weatherCondition = "clear";
  String _currentDisplayText = "Welcome to Salate Browser";
  SearchEngine _selectedSearchEngine = SearchEngine.google;
  SearchCategory _selectedSearchCategory = SearchCategory.web;
  bool _showWelcome = false;
  Timer? _textSwitchTimer;
  final TextEditingController _bodySearchController = TextEditingController();
  late VideoPlayerController _sunnyController;
  final List<Map<String, dynamic>> _aiTools = [
    {
      'name': 'ChatGPT',
      'url': 'https://chat.openai.com',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'name': 'Gemini',
      'url': 'https://gemini.google.com',
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'Claude AI',
      'url': 'https://claude.ai',
      'icon': Icons.psychology_alt_outlined,
    },
    {
      'name': 'Copilot',
      'url': 'https://copilot.microsoft.com',
      'icon': Icons.smart_toy_outlined,
    },
    {
      'name': 'Perplexity',
      'url': 'https://www.perplexity.ai',
      'icon': Icons.bubble_chart_outlined,
    },
    {
      'name': 'You.com AI',
      'url': 'https://you.com',
      'icon': Icons.explore_outlined,
    },
    {
      'name': 'Poe',
      'url': 'https://poe.com',
      'icon': Icons.memory_outlined,
    },
    {
      'name': 'HuggingChat',
      'url': 'https://huggingface.co/chat/',
      'icon': Icons.tag_faces_outlined,
    },
  ];

  static const platform = MethodChannel('com.salate.browser/role');

  int _dashboardTabIndex = 0; // 0 = Search With, 1 = Search On

  @override
  void initState() {
    super.initState();
    _urlController.text = _tabs[_currentTabIndex].url;
    _loadUserName();
    _loadHistory();
    _loadTabs();
    _loadWeatherData();
    _checkDefaultBrowser(); // [NEW] Check logic
    // Show welcome text first
    _currentDisplayText = "Welcome to Salate Browser";
    _showWelcome = false;

    // Start the shuffling timer after a short delay (e.g. 3s)
    Future.delayed(const Duration(seconds: 3), () {
      _textSwitchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        setState(() {
          _showWelcome = !_showWelcome;
          _currentDisplayText = _showWelcome
              ? "Welcome to Salate Browser"
              : (_weatherCondition.isNotEmpty
                  ? _weatherCondition
                  : "Weather Info");
        });
      });
    });
    // Load weather
    _loadWeatherData();
    _loadSearchPreferences();
    _sunnyController =
        VideoPlayerController.asset('assets/weather/clear_vd.mp4')
          ..initialize().then((_) {
            setState(() {}); // Refresh after initialized
            _sunnyController.setLooping(true);
            _sunnyController.setVolume(0); // Mute
            _sunnyController.play();
          });

    _initAppLinks();

    // Load tabs first, then handle initial link if any
    _loadTabs().then((_) {
      if (widget.initialUrl != null) {
        _handleIncomingLink(widget.initialUrl!);
      }
    });
  }

  void _initAppLinks() {
    AppLinks().uriLinkStream.listen((uri) {
      debugPrint("DEBUG: Received deep link stream: $uri");
      _handleIncomingLink(uri.toString());
    });
  }

  void _handleIncomingLink(String url) {
    debugPrint("DEBUG: Handling incoming link: $url");
    if (_isFile(url)) {
      _openFileViewer(url);
    } else {
      // Add a new tab for the link
      _addNewTabWithUrl(url);
    }
  }

  void _addNewTabWithUrl(String url) {
    setState(() {
      final newTab = TabModel(url: url, isHomepage: false);
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _urlController.text = url;
      _isUrlReadOnly = true;
    });
    TabsManager.saveTabs(_tabs);
    debugPrint(
        "DEBUG: Switched to new tab at index $_currentTabIndex for URL: $url");
  }

  bool _isFile(String url) {
    final mimeType = lookupMimeType(url);
    if (mimeType != null) {
      if (mimeType.startsWith('video/') ||
          mimeType.startsWith('image/') ||
          mimeType == 'application/pdf') {
        return true;
      }
    }
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.pdf') ||
        lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp');
  }

  void _openFileViewer(String url) {
    final mimeType = lookupMimeType(url);
    if (mimeType != null) {
      if (mimeType.startsWith('video/')) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => VideoViewerPage(url: url)));
        return;
      } else if (mimeType.startsWith('image/')) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ImageViewerPage(url: url)));
        return;
      } else if (mimeType == 'application/pdf') {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PdfViewerPage(url: url)));
        return;
      }
    }
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => PdfViewerPage(url: url)));
    } else if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.webm')) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => VideoViewerPage(url: url)));
    } else if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImageViewerPage(url: url)));
    }
  }

  // [NEW] Logic to check default browser annually
  Future<void> _checkDefaultBrowser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPromptStr = prefs.getString('last_default_browser_prompt');
    DateTime? lastPrompt;
    if (lastPromptStr != null) {
      lastPrompt = DateTime.tryParse(lastPromptStr);
    }

    // Default to 'old enough' if never prompted, so we prompt on first run (or you can set it to now to skip first run)
    // User requirement: "make it ask only once a year".
    // I'll interpret this as: prompt if it's been > 365 days.
    final now = DateTime.now();
    bool shouldPrompt = false;

    if (lastPrompt == null) {
      shouldPrompt = true;
    } else {
      final difference = now.difference(lastPrompt).inDays;
      if (difference >= 365) {
        shouldPrompt = true;
      }
    }

    if (shouldPrompt) {
      // Invoke the platform channel
      try {
        // Just triggering the request. The OS handles the specific UI.
        await platform.invokeMethod('requestDefaultBrowser');
        // Update stored time
        await prefs.setString(
            'last_default_browser_prompt', now.toIso8601String());
      } catch (e) {
        debugPrint("Failed to request default browser: $e");
      }
    }
  }

  @override
  void dispose() {
    _textSwitchTimer?.cancel();
    _sunnyController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final lastPrompt = prefs.getString('location_permission_prompt_date');
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        if (lastPrompt != today) {
          permission = await Geolocator.requestPermission();
          await prefs.setString('location_permission_prompt_date', today);
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            throw Exception(
                "User denied permissions to access the device's location.");
          }
        } else {
          debugPrint("Location permission already prompted today. Skipping.");
          return;
        }
      }

      // New way using LocationSettings
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final city = placemarks.first.locality ?? "Unknown";

      final weather = await WeatherService.fetchWeather(city);
      if (weather != null) {
        setState(() {
          _locationName = city;
          _humidity = weather['humidity']?.toDouble();
          _temperature = weather['temp_c']?.toDouble();
          _weatherIconUrl = 'https:${weather['icon']}';
          _weatherCondition = weather['condition'] ?? "Cloudy";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting location/weather: $e");
      }
    }
  }

  Future<void> _loadSearchPreferences() async {
    final engine = await SearchPreferenceManager.loadSearchEngine();
    final category = await SearchPreferenceManager.loadSearchCategory();
    setState(() {
      _selectedSearchEngine = engine;
      _selectedSearchCategory = category;
    });
  }

  Future<void> _updateSearchEngine(SearchEngine engine) async {
    await SearchPreferenceManager.saveSearchEngine(engine);
    setState(() {
      _selectedSearchEngine = engine;
    });
  }

  Future<void> _updateSearchCategory(SearchCategory category) async {
    await SearchPreferenceManager.saveSearchCategory(category);
    setState(() {
      _selectedSearchCategory = category;
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      _nameController.text = _userName!;
    });
  }

  Future<void> _saveUserName(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    setState(() {
      _userName = _nameController.text.trim();
    });
  }

  void _loadHistory() async {
    _history.addAll(await HistoryManager.loadHistory());
    setState(() {});
  }

  Future<void> _loadTabs() async {
    List<TabModel> savedTabs = await TabsManager.loadTabs();
    if (savedTabs.isNotEmpty) {
      setState(() {
        // [FIX] Don't clear if we already added a tab (e.g. initialUrl handled fast)
        // Instead, merge or check if we only have the default placeholder
        if (_tabs.length == 1 &&
            _tabs[0].url == "about:blank" &&
            _tabs[0].isHomepage) {
          _tabs.clear();
        }

        _tabs.addAll(savedTabs);
        _tabs.sort(_tabSort); // Ensure pinned tabs stay on top

        // If we merged, we might want to stay on the newly added tab if one exists
        // Otherwise default to 0
        if (_currentTabIndex >= _tabs.length) {
          _currentTabIndex = 0;
        }

        // Sync desktop mode for the current tab
        if (_tabs.isNotEmpty) {
          _desktopModeManager
              .setDesktopMode(_tabs[_currentTabIndex].isDesktopMode);
          _urlController.text = _tabs[_currentTabIndex].isHomepage
              ? ""
              : _tabs[_currentTabIndex].url;
        }
      });
    }
  }

  int _tabSort(TabModel a, TabModel b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height; // Unused in build
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = _controllers[_currentTabIndex];
        if (controller != null && await controller.canGoBack()) {
          controller.goBack();
        } else {
          // If cannot go back in WebView or we are on Homepage:
          // Maybe minimize app or do nothing? Default behavior is nothing here.
          // Implement double-tap to exit if needed, but for now just block pop.
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          title: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe Right -> Previous Tab
                if (_currentTabIndex > 0) {
                  setState(() {
                    _currentTabIndex--;
                  });
                  _updateUrlBarForTab(_currentTabIndex);
                }
              } else if (details.primaryVelocity! < 0) {
                // Swipe Left -> Next Tab
                if (_currentTabIndex < _tabs.length - 1) {
                  setState(() {
                    _currentTabIndex++;
                  });
                  _updateUrlBarForTab(_currentTabIndex);
                }
              }
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  children: [
                    HomeButton(
                        onPressed: _goToHomePage, iconColor: primaryColor),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        focusNode: _urlFocusNode,
                        readOnly: _isUrlReadOnly,
                        decoration: InputDecoration(
                          hintText: 'Search or enter URL',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02),
                        ),
                        style: TextStyle(fontSize: screenWidth * 0.038),
                        textInputAction: TextInputAction.go,
                        onSubmitted: (val) {
                          _handleNavigation(val);
                          setState(() {
                            _isUrlReadOnly = true;
                          });
                        },
                        onTap: () {
                          setState(() {
                            _isUrlReadOnly = false;
                          });
                        },
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isUrlReadOnly = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                // Overlay for Gestures (Swipe) - Only when ReadOnly
                if (_isUrlReadOnly)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        // Forward tap to enable editing
                        _urlFocusNode.requestFocus();
                        setState(() {
                          _isUrlReadOnly = false;
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        // Handle Swipes
                        if (details.primaryVelocity! > 0) {
                          if (_currentTabIndex > 0) {
                            setState(() {
                              _currentTabIndex--;
                            });
                            _updateUrlBarForTab(_currentTabIndex);
                          }
                        } else if (details.primaryVelocity! < 0) {
                          if (_currentTabIndex < _tabs.length - 1) {
                            setState(() {
                              _currentTabIndex++;
                            });
                            _updateUrlBarForTab(_currentTabIndex);
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.add,
                    color: primaryColor, size: screenWidth * 0.075),
                onPressed: _addNewTab),
            IconButton(
                icon: Icon(Icons.tab,
                    color: primaryColor, size: screenWidth * 0.06),
                onPressed: _showAllTabs),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: primaryColor, size: screenWidth * 0.065),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 12),
                      const Text('History'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'extensions',
                  child: Row(
                    children: [
                      Icon(Icons.extension,
                          color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 12),
                      const Text('Extensions'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'desktop',
                  child: Row(
                    children: [
                      Icon(Icons.desktop_mac,
                          color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 12),
                      const Text('Desktop Mode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 12),
                      const Text('Settings'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'history') {
                  _showHistory();
                } else if (value == 'extensions') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtensionManager(
                        onThemeToggle: widget.onThemeToggle,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                } else if (value == 'desktop') {
                  _toggleDesktopMode();
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        isDarkMode: widget.isDarkMode,
                        onThemeToggle: widget.onThemeToggle,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _currentTabIndex,
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;

              return KeyedSubtree(
                key: ObjectKey(tab),
                child: tab.isHomepage
                    ? _buildHomeContent(context)
                    : InAppWebView(
                        key: ValueKey('webview_$index'),
                        initialSettings: _desktopModeManager.getSettings(),
                        initialUrlRequest:
                            URLRequest(url: WebUri.uri(Uri.parse(tab.url))),
                        onWebViewCreated: (controller) {
                          _controllers[index] = controller;
                          if (index == _currentTabIndex) {
                            _desktopModeManager
                                .setWebViewController(controller);
                          }
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                          var uri = navigationAction.request.url;
                          if (uri != null) {
                            String url = uri.toString();
                            if (_isFile(url)) {
                              _openFileViewer(url);
                              return NavigationActionPolicy.CANCEL;
                            }
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                        onProgressChanged: (controller, progress) async {
                          if (progress == 100) {
                            await _desktopModeManager.injectViewportLogic();
                          }
                        },
                        onLoadStop: (controller, url) async {
                          if (url != null) {
                            debugPrint("DEBUG: onLoadStop: $url");
                            try {
                              _tabs[index].url = url.toString();
                              _tabs[index].title =
                                  _extractTitleFromUrl(url.toString());
                              _tabs[index].faviconUrl =
                                  _generateFaviconUrl(url.toString());

                              if (index == _currentTabIndex) {
                                setState(() {
                                  _urlController.text = url.toString();
                                });
                              }

                              if (!_history
                                  .any((item) => item.url == url.toString())) {
                                final historyItem = HistoryItem(
                                    url: url.toString(),
                                    timestamp: DateTime.now());
                                _history.add(historyItem);
                                HistoryManager.saveHistory(_history);
                              }
                              TabsManager.saveTabs(_tabs);
                            } catch (e) {
                              debugPrint("Error in onLoadStop: $e");
                            }
                            await _desktopModeManager.injectViewportLogic();
                          }
                        },
                        onUpdateVisitedHistory:
                            (controller, url, androidIsReload) {
                          if (url != null) {
                            if (index == _currentTabIndex) {
                              setState(() {
                                _urlController.text = url.toString();
                              });
                            }
                            _tabs[index].url = url.toString();
                            _tabs[index].title =
                                _extractTitleFromUrl(url.toString());
                            TabsManager.saveTabs(_tabs);
                          }
                        },
                      ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _updateUrlBarForTab(int index) {
    if (_tabs[index].isHomepage) {
      _urlController.clear();
      // Set desktop mode false?
    } else {
      _urlController.text = _tabs[index].url;
      // Set desktop mode manager controller
      final controller = _controllers[index];
      if (controller != null) {
        _desktopModeManager.setWebViewController(controller);
      }
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final cardColor = isDark ? const Color(0xFF172554) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final minuteColor = isDark ? const Color(0xFF60A5FA) : Colors.deepOrange;
    final padding = screenWidth * 0.05;
    final fieldFontSize = screenWidth * 0.04;
    final dateFontSize = screenWidth * 0.038;
    final iconSize = screenWidth * 0.055;
    final clockSize = screenWidth * 0.4;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  // Top Row with Clock and Name Input - Always Visible
                  Row(
                    children: [
                      SizedBox(
                        width: clockSize,
                        height: clockSize,
                        child: WavyClockWidget(),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: fieldFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Your Name",
                                  hintStyle: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: fieldFontSize,
                                  ),
                                  border: InputBorder.none,
                                  icon: Icon(Icons.person_outline,
                                      color: primaryColor, size: iconSize),
                                ),
                                onChanged: (val) {
                                  _saveUserName(val);
                                },
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: iconSize - 1, color: primaryColor),
                                SizedBox(width: screenWidth * 0.025),
                                Text(
                                  DateFormat('EEE, MMM d, y')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: dateFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.0005),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.1),
                          ),
                          child: TextField(
                            controller: _bodySearchController,
                            style: TextStyle(fontSize: screenWidth * 0.04),
                            decoration: InputDecoration(
                              hintText: "Search or type URL",
                              hintStyle:
                                  TextStyle(fontSize: screenWidth * 0.04),
                              border: InputBorder.none,
                              icon: Icon(Icons.search,
                                  size: iconSize + 3, color: primaryColor),
                            ),
                            onSubmitted: (query) => _handleNavigation(query),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.1)),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.017,
                          ),
                        ),
                        onPressed: () {
                          final query = _bodySearchController.text.trim();
                          if (query.isNotEmpty) {
                            _handleNavigation(query);
                          }
                        },
                        child: Text("Search",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04)),
                      )
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Weather Card - Always visible
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.85),
                      ),
                      child: Stack(
                        children: [
                          // 🌧️ Rainy background
                          if (_weatherCondition
                                  .toLowerCase()
                                  .contains("rain") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("drizzle") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("showers"))
                            Positioned.fill(
                              child: Image.asset(
                                "assets/weather/rainy_bg.jpg",
                                fit: BoxFit.cover,
                              ),
                            ),

                          // 🌧️ Optional Rain overlay
                          if (_weatherCondition.toLowerCase().contains("rain"))
                            Positioned.fill(
                              child: Opacity(
                                opacity: 1.0,
                                child: Image.asset(
                                  "assets/weather/rain_overlay.gif",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          if (_weatherCondition
                                  .toLowerCase()
                                  .contains("clear") ||
                              _weatherCondition.toLowerCase().contains("sunny"))
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.05),
                                child: _sunnyController.value.isInitialized
                                    ? Opacity(
                                        opacity: 1.0,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _sunnyController
                                                .value.size.width,
                                            height: _sunnyController
                                                .value.size.height,
                                            child:
                                                VideoPlayer(_sunnyController),
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ),
                            ),

                          if (_weatherCondition
                                  .toLowerCase()
                                  .contains("cloudy") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("overcast"))
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.05),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      "assets/weather/cloudy_bg.jpg",
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (_weatherCondition.toLowerCase().contains("fog") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("haze") ||
                              _weatherCondition.toLowerCase().contains("mist"))
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.05),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      "assets/weather/foggy_bg2.avif",
                                      fit: BoxFit.cover,
                                    ),
                                    Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        "assets/weather/fog_overlay.gif",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (_weatherCondition
                                  .toLowerCase()
                                  .contains("thunder") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("storm") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("lightning") ||
                              _weatherCondition
                                  .toLowerCase()
                                  .contains("thunderstorm"))
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.05),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      "assets/weather/thunderstorm_bg3.jpg",
                                      fit: BoxFit.cover,
                                    ),
                                    Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        "assets/weather/thunder_overlay3.gif",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 🌤️ Your actual weather card content
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.05),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Weather Text with Icon
                                Row(
                                  children: [
                                    if (_weatherIconUrl != null &&
                                        _weatherIconUrl!.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                            right: screenWidth * 0.02),
                                        child: Image.network(
                                          _weatherIconUrl!,
                                          width: screenWidth * 0.07,
                                          height: screenWidth * 0.07,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.cloud,
                                            size: screenWidth * 0.06,
                                            color: minuteColor,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: EdgeInsets.only(
                                            right: screenWidth * 0.02),
                                        child: Icon(
                                          Icons.wb_sunny_outlined,
                                          size: screenWidth * 0.06,
                                        ),
                                      ),
                                    SizedBox(width: screenWidth * 0.025),
                                    Expanded(
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        transitionBuilder: (Widget child,
                                            Animation<double> animation) {
                                          final inAnimation = Tween<Offset>(
                                            begin: const Offset(0.0, 1.0),
                                            end: Offset.zero,
                                          ).animate(animation);

                                          final outAnimation = Tween<Offset>(
                                            begin: Offset.zero,
                                            end: const Offset(0.0, -1.0),
                                          ).animate(animation);

                                          return SlideTransition(
                                            position: child.key ==
                                                    ValueKey(
                                                        _currentDisplayText)
                                                ? inAnimation
                                                : outAnimation,
                                            child: FadeTransition(
                                                opacity: animation,
                                                child: child),
                                          );
                                        },
                                        child: Text(
                                          _currentDisplayText,
                                          key: ValueKey<String>(
                                              _currentDisplayText),
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.05,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                // Humidity Indicator
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.013,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4285F4),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Humidity ${(_humidity ?? 69).toInt()}%",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.045,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.25,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.005,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor:
                                                    (_humidity ?? 69) / 100,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.12,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4285F4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.water_drop,
                                        color: Colors.white,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.06,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Temperature and Location
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.015,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.thermostat,
                                              color: Color(0xFF4285F4),
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            SizedBox(width: screenWidth * 0.02),
                                            Expanded(
                                              child: Text(
                                                "Feels ${_temperature?.toStringAsFixed(1) ?? '--'}°C",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.038,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1F2937),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.015,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4285F4),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: screenWidth * 0.05,
                                            ),
                                            SizedBox(width: screenWidth * 0.02),
                                            Expanded(
                                              child: Text(
                                                _locationName ?? "--",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Unified Premium Search Dashboard
                  _buildSearchDashboard(screenWidth, screenHeight),

                  if (keyboardHeight == 0)
                    SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
        // Bottom Icon Row (Pinned) - Hide when keyboard is open
        if (keyboardHeight == 0)
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _iconButton(Icons.smart_toy, primaryColor, screenWidth, null,
                    showAiMenu: true), // AI Hub
                _iconButton(Icons.ondemand_video, primaryColor, screenWidth,
                    'https://www.youtube.com'),
                _iconButton(Icons.email_outlined, primaryColor, screenWidth,
                    'https://mail.google.com'),
                _iconButton(Icons.map, primaryColor, screenWidth,
                    'https://maps.google.com'),
                _iconButton(Icons.cloud, primaryColor, screenWidth,
                    'https://drive.google.com'),
                _iconButton(Icons.apps, primaryColor, screenWidth, null,
                    showAppMenu: true),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchDashboard(double screenWidth, double screenHeight) {
    // Re-derive app colors to match homepage style
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF172554) : Colors.white;

    // A single unified premium card with TABS
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(
          screenWidth * 0.045), // Increased padding for premium feel
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Tab Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderTab("Search With", 0, screenWidth),
              _buildHeaderTab("Search On", 1, screenWidth),
            ],
          ),

          SizedBox(height: screenHeight * 0.02), // Increased separator

          // Row 2: Dynamic Content Area
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _dashboardTabIndex == 0
                ? KeyedSubtree(
                    key: const ValueKey("SearchWith"),
                    child: _buildSearchWithGrid(screenWidth),
                  )
                : KeyedSubtree(
                    key: const ValueKey("SearchOn"),
                    child: _buildSearchOnGrid(screenWidth),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(String title, int index, double screenWidth) {
    final isSelected = _dashboardTabIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final Color textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        setState(() {
          _dashboardTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03, vertical: screenWidth * 0.005),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w700,
            color: isSelected ? primaryColor : textColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchWithGrid(double screenWidth) {
    // 2x2 Grid for Engines
    // We use Column + Row to avoid ScrollView, ensuring strict 2x2
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildGridCapsule(
                    SearchEngine.google, Icons.search, screenWidth)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
                child: _buildGridCapsule(
                    SearchEngine.duckduckgo, Icons.privacy_tip, screenWidth)),
          ],
        ),
        SizedBox(height: screenWidth * 0.035),
        Row(
          children: [
            Expanded(
                child: _buildGridCapsule(
                    SearchEngine.bing, Icons.window, screenWidth)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
                child: _buildGridCapsule(
                    SearchEngine.brave, Icons.shield, screenWidth)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchOnGrid(double screenWidth) {
    // Custom Layout for Categories
    // Top Row: Web, Images, YouTube (3)
    // Bottom Row: Reddit, Wiki (2, centered)
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildCategoryGridCapsule(
                    SearchCategory.web, Icons.language, screenWidth)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
                child: _buildCategoryGridCapsule(
                    SearchCategory.images, Icons.image, screenWidth)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
                child: _buildCategoryGridCapsule(SearchCategory.youtube,
                    Icons.play_arrow_rounded, screenWidth)),
          ],
        ),
        SizedBox(height: screenWidth * 0.035),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: _buildCategoryGridCapsule(
                    SearchCategory.reddit, Icons.forum, screenWidth)),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
                child: _buildCategoryGridCapsule(
                    SearchCategory.wikipedia, Icons.menu_book, screenWidth)),
            // Spacer to keep same Grid sizing if we wanted 3 cols,
            // but for 2 centered we can just use Expanded or Flexible.
            // Using Expanded fills the row, so let's stick to 2 items filling the width for a balanced "blocky" look.
          ],
        ),
      ],
    );
  }

  Widget _buildGridCapsule(
      SearchEngine engine, IconData icon, double screenWidth) {
    final isSelected = _selectedSearchEngine == engine;

    // Re-derive app colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final Color cardColor = isDark ? const Color(0xFF172554) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ScaleButton(
      onTap: () => _updateSearchEngine(engine),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : cardColor, // Consistent with app card color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenWidth * 0.05,
              color: isSelected
                  ? Colors.white
                  : primaryColor.withValues(alpha: 0.8),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              engine.displayName,
              style: TextStyle(
                fontSize: screenWidth * 0.028,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : textColor.withValues(alpha: 0.8),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridCapsule(
      SearchCategory category, IconData icon, double screenWidth) {
    final isSelected = _selectedSearchCategory == category;

    // Re-derive app colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final Color cardColor = isDark ? const Color(0xFF172554) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ScaleButton(
      onTap: () => _updateSearchCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : cardColor, // Consistent with app card color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenWidth * 0.05,
              color: isSelected
                  ? Colors.white
                  : primaryColor.withValues(alpha: 0.8),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              category.displayName,
              style: TextStyle(
                fontSize: screenWidth * 0.028,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : textColor.withValues(alpha: 0.8),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
      IconData icon, Color color, double screenWidth, String? url,
      {bool showAppMenu = false, bool showAiMenu = false}) {
    final screenHeight = MediaQuery.of(context).size.height;
    //final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        if (showAppMenu) {
          // show google app menu
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              height: screenHeight * 0.5,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _googleAppTile('YouTube', Icons.ondemand_video,
                      'https://www.youtube.com'),
                  _googleAppTile(
                      'Gmail', Icons.email, 'https://mail.google.com'),
                  _googleAppTile(
                      'Drive', Icons.cloud, 'https://drive.google.com'),
                  _googleAppTile('Maps', Icons.map, 'https://maps.google.com'),
                  _googleAppTile('Calendar', Icons.calendar_today,
                      'https://calendar.google.com'),
                  _googleAppTile(
                      'Photos', Icons.photo, 'https://photos.google.com'),
                  _googleAppTile('Classroom', Icons.class_,
                      'https://classroom.google.com'),
                  _googleAppTile(
                      'Docs', Icons.description, 'https://docs.google.com'),
                  _googleAppTile(
                      'Sheets', Icons.table_chart, 'https://sheets.google.com'),
                  _googleAppTile(
                      'Slides', Icons.slideshow, 'https://slides.google.com'),
                  _googleAppTile(
                      'News', Icons.article, 'https://news.google.com'),
                  _googleAppTile(
                      'Meet', Icons.video_call, 'https://meet.google.com'),
                ],
              ),
            ),
          );
        } else if (showAiMenu) {
          // Show AI Menu
          _showAiMenu();
        } else if (url != null) {
          _handleSearch(url);
        }
      },
      child: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15), // Lint fix
        radius: screenWidth * 0.06,
        child: Icon(icon, color: color, size: screenWidth * 0.055),
      ),
    );
  }

// Google app tile used in the modal
  Widget _googleAppTile(String name, IconData icon, String url) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _handleSearch(url);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.1), // Lint fix
            radius: screenWidth * 0.075, // ~28 on standard width
            child: Icon(
              icon,
              size: screenWidth * 0.08, // ~24 on standard width
              color: primaryColor,
            ),
          ),
          SizedBox(height: screenHeight * 0.01), // ~8 on typical height
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.03, // ~12 on standard width
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showAiMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: _aiTools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final ai = _aiTools[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _handleSearch(ai['url']);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1), // Lint fix
                      radius: 28,
                      child: Icon(ai['icon'],
                          size: 24,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ai['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

// Function to open a URL (like search bar)
  void _handleSearch(String url) {
    _handleNavigation(url);
  }

  void _handleNavigation(String input) {
    if (input.isEmpty) return;

    final url = Uri.tryParse(input)?.hasScheme ?? false
        ? input
        : _selectedSearchCategory.constructSearchUrl(
            input, _selectedSearchEngine);

    setState(() {
      // Modify existing tab to preserve ObjectKey
      if (_tabs[_currentTabIndex].isHomepage) {
        _tabs[_currentTabIndex].isHomepage = false;
        // New WebView will be created with initialUrl = url
      } else {
        // Already a webview, so load the url
        _controllers[_currentTabIndex]
            ?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      }
      _tabs[_currentTabIndex].url = url;
      _tabs[_currentTabIndex].title = _extractTitleFromUrl(url);
      _tabs[_currentTabIndex].faviconUrl = _generateFaviconUrl(url);

      _urlController.text = url;
      _tabs.sort(_tabSort);
    });

    TabsManager.saveTabs(_tabs);
    HistoryManager.saveHistory(_history);
  }

  String _generateFaviconUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    // Use Google's service which is robust
    return 'https://www.google.com/s2/favicons?sz=64&domain=${uri.host}';
  }

  String _extractTitleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null ? uri.host.replaceAll("www.", "") : "Untitled";
  }

  Future<void> _saveCurrentTabState() async {
    try {
      if (!_tabs[_currentTabIndex].isHomepage) {
        final controller = _controllers[_currentTabIndex];
        if (controller != null) {
          final url = await controller.getUrl();
          if (url != null) {
            final title = await controller.getTitle();
            setState(() {
              _tabs[_currentTabIndex].url = url.toString();
              if (title != null) {
                _tabs[_currentTabIndex].title = title;
              }
              _tabs[_currentTabIndex].faviconUrl =
                  _generateFaviconUrl(url.toString());
            });
            await TabsManager.saveTabs(_tabs);
          }
        }
      }
    } catch (e) {
      debugPrint("Error saving tab state: $e");
    }
  }

  void _addNewTab() async {
    await _saveCurrentTabState(); // Save current before creating new
    setState(() {
      _tabs.add(TabModel(url: "about:blank", isHomepage: true));
      _tabs.sort(_tabSort);
      _currentTabIndex = _tabs.length - 1;
    });
    // New tab (Homepage) doesn't have a WebView yet
    _desktopModeManager.setDesktopMode(false);
    _urlController.clear(); // Home is empty URL
    TabsManager.saveTabs(_tabs);
  }

  void _showAllTabs() async {
    await _saveCurrentTabState(); // Save current before switching context
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllTabsPage(
          tabs: _tabs,
          onTabSelected: (index) {
            setState(() => _currentTabIndex = index);
            Navigator.pop(context);

            // Sync URL Bar and Desktop Mode
            final url = _tabs[_currentTabIndex].url;
            _urlController.text = _tabs[_currentTabIndex].isHomepage ? '' : url;
            _desktopModeManager
                .setDesktopMode(_tabs[_currentTabIndex].isDesktopMode);

            final controller = _controllers[_currentTabIndex];
            if (controller != null) {
              _desktopModeManager.setWebViewController(controller);
            }
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);
              // Adjust current index if needed
              if (_currentTabIndex >= index && _currentTabIndex > 0) {
                _currentTabIndex--;
              }
              if (_tabs.isEmpty) {
                // Always keep at least one tab
                _tabs
                    .add(TabModel(url: "https://google.com", isHomepage: true));
                _currentTabIndex = 0;
              } else if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.length - 1;
              }
            });
            TabsManager.saveTabs(_tabs);

            // Sync UI for new current tab
            final url = _tabs[_currentTabIndex].url;
            _urlController.text = _tabs[_currentTabIndex].isHomepage ? '' : url;
            // No need to loadUrl, IndexedStack handles it.
          },
          onAddNewTab: _addNewTab,
          onReorderTabs: (newTabs) {
            setState(() {
              _tabs.clear();
              _tabs.addAll(newTabs);
            });
            TabsManager.saveTabs(_tabs);
          },
          onTogglePin: (index) {
            setState(() {
              _tabs[index].isPinned = !_tabs[index].isPinned;
              _tabs.sort(_tabSort);
            });
            TabsManager.saveTabs(_tabs);
          },
        ),
      ),
    );
  }

  void _showHistory() async {
    List<HistoryItem> history = await HistoryManager.loadHistory();

    if (!mounted) return;

    _showHistorySheet(history); // Move UI rendering to a separate function
  }

  void _showHistorySheet(List<HistoryItem> history) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        children: [
          ListTile(
            title: const Text('Browsing History'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final ctx = context;
                await HistoryManager.clearHistory();
                if (ctx.mounted && Navigator.canPop(ctx)) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() => _history.clear());
                }
              },
              tooltip: 'Clear History',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                // Show newest first
                final item = history[history.length - 1 - index];
                String displayTitle = "Page";
                try {
                  displayTitle = _extractTitleFromUrl(item.url);
                } catch (_) {
                  displayTitle = item.url;
                }

                return ListTile(
                  title: Text(displayTitle, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.url, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigation(item.url);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goToHomePage() async {
    await _saveCurrentTabState(); // Save current before going home? Actually we overwrite it.
    // If we go home, we effectively replace the current URL with Home.
    // So we don't need to save the *previous* URL as the *current* state of this tab.
    setState(() {
      _tabs[_currentTabIndex] =
          TabModel(url: "https://google.com", isHomepage: true);

      // [NEW] Clear inputs
      _urlController.clear();
      _bodySearchController.clear();
    });
  }

  void _toggleDesktopMode() async {
    await _saveCurrentTabState();
    final newMode = !_desktopModeManager.isDesktopMode;
    await _desktopModeManager.setDesktopMode(newMode);

    setState(() {
      _tabs[_currentTabIndex].isDesktopMode = newMode;
    });

    await TabsManager.saveTabs(_tabs);
  }
}

class HomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const HomeButton(
      {super.key, required this.onPressed, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.home),
      color: iconColor,
      onPressed: onPressed,
    );
  }
}

class ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const ScaleButton({super.key, required this.onTap, required this.child});

  @override
  State<ScaleButton> createState() =>
      _ScaleButtonState(); // Lint fix: Return specific state type
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
