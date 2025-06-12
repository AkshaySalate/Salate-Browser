import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/pages/extension_manager.dart';
import 'package:salate_browser/utils/tabs_manager.dart';
import 'package:salate_browser/pages/all_tabs_page.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';
import 'package:salate_browser/utils/weather_service.dart';
import 'package:salate_browser/widgets/wavy_clock_widget.dart';

class BrowserHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const BrowserHomePage({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class BrowserHomePageState extends State<BrowserHomePage> {
  final List<TabModel> _tabs = [TabModel(url: "https://google.com", isHomepage: true)];
  final List<HistoryItem> _history = [];
  final DesktopModeManager _desktopModeManager = DesktopModeManager();
  int _currentTabIndex = 0;
  late InAppWebViewController _webViewController;
  String _userName = "";
  double? _humidity;
  double? _temperature;
  String? _weatherIconUrl;
  String? _locationName;
  String _weatherCondition = "Cloudy";
  String _currentDisplayText = "Welcome to Salate Browser";
  bool _showWelcome = false;
  Timer? _textSwitchTimer;
  final TextEditingController _bodySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTabs();
    _loadWeatherData();
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
              : (_weatherCondition.isNotEmpty ? _weatherCondition : "Weather Info");
        });
      });
    });
    // Load weather
    _loadWeatherData();
  }

  @override
  void dispose() {
    _textSwitchTimer?.cancel();
    super.dispose();
  }
  Future<void> _loadWeatherData() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception("User denied permissions to access the device's location.");
        }
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
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
      print("Error getting location/weather: $e");
    }
  }

  void _loadHistory() async {
    _history.addAll(await HistoryManager.loadHistory());
    setState(() {});
  }

  void _loadTabs() async {
    List<TabItem> savedTabs = await TabsManager.loadTabs();
    if (savedTabs.isNotEmpty) {
      setState(() {
        _tabs.clear(); // Clear existing tabs before loading
        _tabs.addAll(savedTabs.map((tab) => TabModel(url: tab.url)));
        _currentTabIndex = 0; // Ensure it starts at the first tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    //final Color primaryColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF60A5FA);
    final Color cardColor = isDark ? const Color(0xFF172554) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    final Color hourColor = isDark ? Colors.white : Colors.purple;
    final Color minuteColor = isDark ? const Color(0xFF60A5FA) : Colors.deepOrange;

    final double padding = screenWidth * 0.05;
    final double fieldFontSize = screenWidth * 0.04; // Scales with screen
    final double dateFontSize = screenWidth * 0.038;
    final double iconSize = screenWidth * 0.055;
    final double clockSize = screenWidth * 0.4; // Responsive clock widget

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Row(
          children: [
            HomeButton(onPressed: _goToHomePage, iconColor: primaryColor,),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search or enter URL',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  //prefixIcon: Icon(Icons.search, color: primaryColor), // ← Primary color
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: _handleNavigation,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.add, color: primaryColor), onPressed: _addNewTab),
          IconButton(icon: Icon(Icons.tab, color: primaryColor), onPressed: _showAllTabs),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryColor), // ← Primary color
            onSelected: (value) {
              if (value == 'history') _showHistory();
              if (value == 'extensions') {
                // Pass the onThemeToggle and isDarkMode when navigating to ExtensionManager
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExtensionManager(
                      onThemeToggle: widget.onThemeToggle,
                      isDarkMode: widget.isDarkMode, // Pass the current theme state
                    ),
                  ),
                );
              }
              if (value == 'desktop_mode') {
                _toggleDesktopMode();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'history', child: Text('History')),
              PopupMenuItem(value: 'extensions', child: Text('Extensions')),
              PopupMenuItem(value: 'desktop_mode', child: Text('Desktop Mode')),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _tabs[_currentTabIndex].isHomepage
            ? SingleChildScrollView(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.01),
              // Top Row with Clock and Name Input
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
                            style: TextStyle(
                              color: textColor,
                              fontSize: fieldFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter your name",
                              hintStyle: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: fieldFontSize,
                              ),
                              border: InputBorder.none,
                              icon: Icon(Icons.person_outline, color: primaryColor, size: iconSize),
                            ),
                            onChanged: (val) => setState(() => _userName = val),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: iconSize - 1, color: primaryColor),
                            SizedBox(width: screenWidth * 0.025),
                            Text(
                              DateFormat('EEE, MMM d, y').format(DateTime.now()),
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
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.0005),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      ),
                      child: TextField(
                        controller: _bodySearchController,
                        style: TextStyle(fontSize: screenWidth * 0.04),
                        decoration: InputDecoration(
                          hintText: "Search or type URL",
                          hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, size: iconSize + 3, color: primaryColor),
                        ),
                        onSubmitted: (query) => _handleNavigation(query),
                      ),

                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.1)),
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

                    child: Text("Search", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                  )
                ],
              ),

              SizedBox(height: screenHeight * 0.025),

              // Weather Card
              Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Text with Icon
                    Row(
                      children: [
                        if (_weatherIconUrl != null && _weatherIconUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              _weatherIconUrl!,
                              width: 28,
                              height: 28,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.cloud,
                                size: 24,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.wb_sunny_outlined, size: 24),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final inAnimation = Tween<Offset>(
                                begin: const Offset(0.0, 1.0),
                                end: Offset.zero,
                              ).animate(animation);

                              final outAnimation = Tween<Offset>(
                                begin: Offset.zero,
                                end: const Offset(0.0, -1.0),
                              ).animate(animation);

                              return SlideTransition(
                                position: child.key == ValueKey(_currentDisplayText)
                                    ? inAnimation
                                    : outAnimation,
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: Text(
                              _currentDisplayText,
                              key: ValueKey<String>(_currentDisplayText),
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Humidity Indicator
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Humidity ${(_humidity ?? 69).toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (_humidity ?? 69) / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4285F4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 20,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.thermostat,
                                  color: Color(0xFF4285F4),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Feels ${_temperature?.toStringAsFixed(1) ?? '--'}°C",
                                    style: const TextStyle(
                                      fontSize: 14,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationName ?? "--",
                                    style: const TextStyle(
                                      fontSize: 14,
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

              SizedBox(height: screenHeight * 0.025),

              // Search Engine Buttons
              Text(
                "Search With",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Wrap(
                spacing: screenWidth * 0.025,
                runSpacing: screenHeight * 0.015,
                children: [
                  _searchEngineButton("Google", Icons.g_mobiledata, primaryColor, textColor, screenWidth * 0.04, screenWidth),
                  _searchEngineButton("Duck", Icons.bubble_chart, primaryColor, textColor, screenWidth * 0.04, screenWidth),
                  _searchEngineButton("Bing", Icons.brightness_5, primaryColor, textColor, screenWidth * 0.04, screenWidth),
                  _searchEngineButton("Brave", Icons.shield, primaryColor, textColor, screenWidth * 0.04, screenWidth),
                ],
              ),

              SizedBox(height: screenHeight * 0.08),

              // Bottom Icon Row
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _iconButton(
                      icon: Icons.ondemand_video,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => _handleSearch("https://www.youtube.com"),
                    ),
                    _iconButton(
                      icon: Icons.email_outlined,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => _handleSearch("https://mail.google.com"),
                    ),
                    _iconButton(
                      icon: Icons.send,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => _handleSearch("https://mail.google.com/mail/u/0/#sent"),
                    ),
                    _iconButton(
                      icon: Icons.call,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => _handleSearch("https://voice.google.com"),
                    ),
                    _iconButton(
                      icon: Icons.videogame_asset,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => _handleSearch("https://stadia.google.com"),
                    ),
                    _iconButton(
                      icon: Icons.apps,
                      color: primaryColor,
                      screenWidth: screenWidth,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              _googleAppTile("YouTube", Icons.ondemand_video, "https://www.youtube.com"),
                              _googleAppTile("Gmail", Icons.email, "https://mail.google.com"),
                              _googleAppTile("Drive", Icons.cloud, "https://drive.google.com"),
                              _googleAppTile("Docs", Icons.description, "https://docs.google.com"),
                              _googleAppTile("Sheets", Icons.table_chart, "https://sheets.google.com"),
                              _googleAppTile("Slides", Icons.slideshow, "https://slides.google.com"),
                              _googleAppTile("Meet", Icons.video_call, "https://meet.google.com"),
                              _googleAppTile("Classroom", Icons.class_, "https://classroom.google.com"),
                              _googleAppTile("News", Icons.newspaper, "https://news.google.com"),
                              _googleAppTile("Maps", Icons.map, "https://maps.google.com"),
                              _googleAppTile("Photos", Icons.photo, "https://photos.google.com"),
                              _googleAppTile("Translate", Icons.translate, "https://translate.google.com"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            : InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(_tabs[_currentTabIndex].url))),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _desktopModeManager.setWebViewController(controller);
          },
          onLoadStop: (controller, url) {
            if (url != null && !_history.any((item) => item.url == url.toString())) {
              final historyItem = HistoryItem(url: url.toString(), timestamp: DateTime.now());
              setState(() => _history.add(historyItem));
              HistoryManager.saveHistory(_history);
            }
          },
        ),
      ),
    );

  }

  Widget _customButton({
    required IconData icon,
    required String label,
    required Color primaryColor,
    required double fontSize,
    required double screenWidth,
  }) {
    return Container(
      width: screenWidth * 0.28, // Responsive width (~110–120 at 400px)
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025), // Responsive vertical padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.07),
        color: primaryColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: screenWidth * 0.045),
          SizedBox(width: screenWidth * 0.015),
          Text(label, style: TextStyle(fontSize: fontSize, color: primaryColor)),
        ],
      ),
    );
  }


  Widget _searchEngineButton(
      String label,
      IconData icon,
      Color color,
      Color textColor,
      double fontSize,
      double screenWidth,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.025,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.07),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: screenWidth * 0.05, color: color),
          SizedBox(width: screenWidth * 0.015),
          Text(label, style: TextStyle(color: textColor, fontSize: fontSize)),
        ],
      ),
    );
  }


  // Modified icon button with onTap
  Widget _iconButton({
    required IconData icon,
    required Color color,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        radius: screenWidth * 0.06,
        child: Icon(icon, color: color, size: screenWidth * 0.055),
      ),
    );
  }


// Google app tile used in the modal
  Widget _googleAppTile(String name, IconData icon, String url) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _handleSearch(url);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

// Function to open a URL (like search bar)
  void _handleSearch(String url) {
    final newTab = TabModel(url: url, isHomepage: false);
    setState(() {
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
    });
  }
  void _handleNavigation(String input) {
    final url = Uri.tryParse(input)?.hasScheme ?? false ? input : 'https://google.com/search?q=$input';
    setState(() => _tabs[_currentTabIndex] = TabModel(url: url, isHomepage: false));
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri.uri(Uri.parse(url))));
    TabsManager.saveTabs(_tabs.cast<TabItem>());  // Save tabs whenever they are modified
    HistoryManager.saveHistory(_history);
  }

  void _addNewTab() {
    setState(() {
      _tabs.add(TabModel(url: "https://google.com", isHomepage: true));
      _currentTabIndex = _tabs.length - 1;  // Switch to the newly added tab
    });
    TabsManager.saveTabs(_tabs.map((tab) => TabItem(url: tab.url)).toList());
  }


  void _showAllTabs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllTabsPage(
          tabs: _tabs,
          onTabSelected: (index) {
            setState(() => _currentTabIndex = index);
            Navigator.pop(context);
          },
          onTabRemoved: (index) {
            setState(() {
              _tabs.removeAt(index);
              if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : 0;
              }
            });
            TabsManager.saveTabs(_tabs.map((tab) => TabItem(url: tab.url)).toList()); // Save updated tabs
          },
        ),
      ),
    );
  }

  void _showHistory() async {
    List<HistoryItem> history = await HistoryManager.loadHistory();

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        children: [
          ListTile(
            title: const Text('Browsing History'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                await HistoryManager.clearHistory();
                Navigator.pop(context); // Close modal
                setState(() => _history.clear()); // Clear local history too
              },
              tooltip: 'Clear History',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, index) {
                final item = history.reversed.toList()[index]; // Latest on top
                return ListTile(
                  title: Text(item.url),
                  subtitle: Text(item.timestamp.toLocal().toString()),
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


  void _goToHomePage() {
    setState(() {
      _tabs[_currentTabIndex] = TabModel(url: "https://google.com", isHomepage: true);
    });
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri("https://google.com")));
  }

  void _toggleDesktopMode() {
    setState(() {
      _desktopModeManager.toggleDesktopMode();
    });
  }
}

class HomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const HomeButton({super.key, required this.onPressed, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.home), color: iconColor,
      onPressed: onPressed,
    );
  }
}