import 'dart:math';
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

class BrowserHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const BrowserHomePage({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  BrowserHomePageState createState() => BrowserHomePageState();
}

class WavyClockWidget extends StatefulWidget {
  const WavyClockWidget({super.key});

  @override
  State<WavyClockWidget> createState() => _WavyClockWidgetState();
}

class _WavyClockWidgetState extends State<WavyClockWidget> with TickerProviderStateMixin {
  late AnimationController? _secondController; // Animation controller for seconds
  late AnimationController? _waveController;   // Animation controller for wave animation

  @override
  void initState() {
    super.initState();

    _secondController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _secondController?.dispose();
    _waveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safeguard: Return an empty container if controllers aren't initialized
    if (_secondController == null || _waveController == null) {
      return const SizedBox.shrink();
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color primaryColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF60A5FA);
    final Color waveColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF60A5FA);
    //final Color waveColor = isDark ? const Color(0xFF172554) : const Color(0xFF60A5FA);
    final Color hourColor = isDark ? Colors.white : Colors.purple;
    final Color minuteColor = isDark ? const Color(0xFF60A5FA) : Colors.deepOrange;
    final Color secondDotColor = isDark ? const Color(0xFF60A5FA) : Colors.purple;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final clockSize = size.clamp(80.0, 150.0);

        return SizedBox(
          width: clockSize,
          height: clockSize,
          child: AnimatedBuilder(
            animation: Listenable.merge([_secondController, _waveController]),
            builder: (context, _) => CustomPaint(
              size: Size(clockSize, clockSize),
              painter: WavyClockPainter(
                datetime: DateTime.now(),
                secondAnimationValue: _secondController!.value,
                waveAnimationValue: _waveController!.value,
                backgroundColor: bgColor,
                waveColor: waveColor,
                hourColor: hourColor,
                minuteColor: minuteColor,
                secondDotColor: secondDotColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class WavyClockPainter extends CustomPainter {
  final DateTime datetime;
  final double secondAnimationValue;
  final double waveAnimationValue;
  final Color backgroundColor;
  final Color waveColor;
  final Color hourColor;
  final Color minuteColor;
  final Color secondDotColor;

  WavyClockPainter({
    required this.datetime,
    required this.secondAnimationValue,
    required this.waveAnimationValue,
    required this.backgroundColor,
    required this.waveColor,
    required this.hourColor,
    required this.minuteColor,
    required this.secondDotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width / 2.2;
    final innerRadius = baseRadius * 0.75;

    // Create multiple wave layers for water-like effect
    _drawWaveLayer(canvas, center, baseRadius, waveAnimationValue, waveColor.withOpacity(0.3), 1.0);
    _drawWaveLayer(canvas, center, baseRadius * 0.95, waveAnimationValue + 0.3, waveColor.withOpacity(0.5), 0.8);
    _drawWaveLayer(canvas, center, baseRadius * 0.9, waveAnimationValue + 0.6, waveColor.withOpacity(0.7), 0.6);

    // Inner circle (main background)
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawCircle(center, innerRadius, backgroundPaint);

    // Hour and Minute Hands
    final hourAngle = (datetime.hour % 12 + datetime.minute / 60) * 30 * pi / 180;
    final minuteAngle = datetime.minute * 6 * pi / 180;

    final hourHandPaint = Paint()
      ..strokeWidth = size.width * 0.045
      ..color = hourColor
      ..strokeCap = StrokeCap.round;

    final minuteHandPaint = Paint()
      ..strokeWidth = size.width * 0.035
      ..color = minuteColor
      ..strokeCap = StrokeCap.round;

    final hourLength = innerRadius * 0.5;
    final minuteLength = innerRadius * 0.75;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * cos(hourAngle - pi / 2),
        center.dy + hourLength * sin(hourAngle - pi / 2),
      ),
      hourHandPaint,
    );

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * cos(minuteAngle - pi / 2),
        center.dy + minuteLength * sin(minuteAngle - pi / 2),
      ),
      minuteHandPaint,
    );

    // Second Dot
    final secondAngle = secondAnimationValue * 2 * pi;
    final secondLength = innerRadius * 0.85;
    final secondOffset = Offset(
      center.dx + secondLength * cos(secondAngle - pi / 2),
      center.dy + secondLength * sin(secondAngle - pi / 2),
    );
    canvas.drawCircle(secondOffset, size.width * 0.02, Paint()..color = secondDotColor);

    // Center Dot
    canvas.drawCircle(center, size.width * 0.015, Paint()..color = Colors.black.withOpacity(0.6));
  }

  void _drawWaveLayer(Canvas canvas, Offset center, double baseRadius, double animationPhase, Color color, double intensity) {
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    const waves = 60;
    final step = 2 * pi / waves;

    // Create water-like shrinking and expanding effect
    final breathingEffect = sin(animationPhase * 2 * pi) * 0.15; // Overall size pulsing
    final rippleEffect = sin(animationPhase * 4 * pi) * 0.05;    // Faster ripple effect

    for (int i = 0; i <= waves; i++) {
      final angle = i * step;

      // Multiple wave frequencies for complex water-like motion
      final wave1 = sin(angle * 4 + animationPhase * 6 * pi) * intensity;
      final wave2 = sin(angle * 6 - animationPhase * 4 * pi) * intensity * 0.6;
      final wave3 = sin(angle * 8 + animationPhase * 8 * pi) * intensity * 0.3;

      // Combine all effects
      final totalWaveEffect = (wave1 + wave2 + wave3) * 3;
      final radiusModification = breathingEffect + rippleEffect + totalWaveEffect * 0.02;

      final r = baseRadius * (1 + radiusModification);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant WavyClockPainter oldDelegate) => true;
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



  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTabs();
    _loadWeatherData();
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
      body: SafeArea(
        child: _tabs[_currentTabIndex].isHomepage
            ? Column(
          children: [
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
                          vertical: screenHeight * 0.0,
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
                            icon: Icon(Icons.person_outline, color: primaryColor,size: iconSize),
                          ),
                          onChanged: (val) => setState(() => _userName = val),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.0),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: iconSize - 1, color: primaryColor),
                          SizedBox(width: screenWidth * 0.025),
                          Center(
                            child: Text(
                              DateFormat('EEE, MMM d, y').format(DateTime.now()),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: dateFontSize,
                                fontWeight: FontWeight.w500,
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

            SizedBox(height: screenHeight * 0.02),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.0005),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      ),
                      child: TextField(
                        style: TextStyle(fontSize: screenWidth * 0.04),
                        decoration: InputDecoration(
                          hintText: "Search or type URL",
                          hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, size: iconSize + 3, color: primaryColor),
                        ),
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
                    onPressed: () {},
                    child: Text("Search", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                  )
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text("Welcome to Salate Browser", style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: textColor)),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // === Humidity Progress Bar ===
                    Text("Humidity", style: TextStyle(fontSize: screenWidth * 0.04, color: primaryColor)),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (_humidity ?? 0) / 100,
                        minHeight: 20,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // === Temp, Icon, Location ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.thermostat, color: primaryColor, size: iconSize),
                            SizedBox(height: 4),
                            Text(
                              _temperature != null ? "${_temperature!.toStringAsFixed(1)}°C" : "--",
                              style: TextStyle(fontSize: screenWidth * 0.035, color: textColor),
                            ),
                          ],
                        ),

                        // Weather Icon
                        _weatherIconUrl != null
                            ? Image.network(_weatherIconUrl!, width: 50, height: 50)
                            : Icon(Icons.cloud_outlined, color: Colors.grey, size: 40),

                        // Location
                        Column(
                          children: [
                            Icon(Icons.location_on, color: primaryColor, size: iconSize),
                            SizedBox(height: 4),
                            Text(
                              _locationName ?? "--",
                              style: TextStyle(fontSize: screenWidth * 0.035, color: textColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),


            const Spacer(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenHeight * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _iconButton(Icons.ondemand_video, primaryColor, screenWidth),
                  _iconButton(Icons.email_outlined, primaryColor, screenWidth),
                  _iconButton(Icons.send, primaryColor, screenWidth),
                  _iconButton(Icons.call, primaryColor, screenWidth),
                  _iconButton(Icons.message, primaryColor, screenWidth),
                  _iconButton(Icons.videogame_asset, primaryColor, screenWidth),
                ],
              ),
            )

          ],
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


  Widget _iconButton(IconData icon, Color color, double screenWidth) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      radius: screenWidth * 0.06, // Responsive radius (~24 for 400px width)
      child: Icon(icon, color: color, size: screenWidth * 0.055),
    );
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