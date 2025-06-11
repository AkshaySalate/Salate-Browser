import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:salate_browser/pages/browser_homepage.dart';
import 'package:salate_browser/pages/extension_manager.dart';
import 'package:salate_browser/utils/tabs_manager.dart';
import 'package:salate_browser/pages/all_tabs_page.dart';
import 'package:salate_browser/models/tab_model.dart';
import 'package:salate_browser/utils/desktop_mode_manager.dart';
import 'package:salate_browser/utils/history_manager.dart';
import 'package:salate_browser/models/history_model.dart';

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

class _WavyClockWidgetState extends State<WavyClockWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat(); // Continuous animation for seconds

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color primaryColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF60A5FA);
    final Color waveColor = isDark ? const Color(0xFF172554) : const Color(0xFFCFE8FF);
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
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size(clockSize, clockSize),
              painter: WavyClockPainter(
                datetime: DateTime.now(),
                animationValue: _controller.value,
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
  final double animationValue;
  final Color backgroundColor;
  final Color waveColor;
  final Color hourColor;
  final Color minuteColor;
  final Color secondDotColor;

  WavyClockPainter({
    required this.datetime,
    required this.animationValue,
    required this.backgroundColor,
    required this.waveColor,
    required this.hourColor,
    required this.minuteColor,
    required this.secondDotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.2;

    final backgroundPaint = Paint()..color = backgroundColor;
    final wavePaint = Paint()..color = waveColor;

    // Draw wavy circle
    final wavyPath = Path();
    const waves = 12;
    final step = 2 * pi / waves;
    for (int i = 0; i <= waves; i++) {
      final angle = i * step;
      final r = radius + 5 * sin(angle * 3); // wave effect
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        wavyPath.moveTo(x, y);
      } else {
        wavyPath.lineTo(x, y);
      }
    }
    wavyPath.close();
    canvas.drawPath(wavyPath, wavePaint);

    // Draw main circle inside
    canvas.drawCircle(center, radius, backgroundPaint);

    // Hour and minute hands
    final hourAngle = (datetime.hour % 12 + datetime.minute / 60) * 30 * pi / 180;
    final minuteAngle = datetime.minute * 6 * pi / 180;

    final hourHandPaint = Paint()
      ..strokeWidth = 10
      ..color = hourColor
      ..strokeCap = StrokeCap.round;

    final minuteHandPaint = Paint()
      ..strokeWidth = 10
      ..color = Colors.deepOrange
      ..strokeCap = StrokeCap.round;

    final hourHandLength = radius * 0.4;
    final minuteHandLength = radius * 0.6;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourHandLength * cos(hourAngle - pi / 2),
        center.dy + hourHandLength * sin(hourAngle - pi / 2),
      ),
      hourHandPaint,
    );

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteHandLength * cos(minuteAngle - pi / 2),
        center.dy + minuteHandLength * sin(minuteAngle - pi / 2),
      ),
      minuteHandPaint,
    );

    // Moving second dot
    final secondAngle = animationValue * 2 * pi;
    final secondDotRadius = 6.0;
    final secondLength = radius * 0.85;

    final secondOffset = Offset(
      center.dx + secondLength * cos(secondAngle - pi / 2),
      center.dy + secondLength * sin(secondAngle - pi / 2),
    );

    canvas.drawCircle(secondOffset, secondDotRadius, Paint()..color = secondDotColor);
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTabs();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0B1D3A) : const Color(0xFFE6F1FF);
    final Color primaryColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF60A5FA);
    final Color cardColor = isDark ? const Color(0xFF172554) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            HomeButton(onPressed: _goToHomePage),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search or enter URL',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: _handleNavigation,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewTab),
          IconButton(icon: const Icon(Icons.tab), onPressed: _showAllTabs),
          PopupMenuButton<String>(
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
                WavyClockWidget(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Enter your name",
                          labelStyle: TextStyle(color: textColor),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        onChanged: (val) => setState(() => _userName = val),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                        style: TextStyle(color: primaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome to Salate Browser", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(child: Text("Humidity", style: TextStyle(color: Colors.white, fontSize: 16))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.water_drop, color: primaryColor, size: 28),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _customButton(icon: Icons.thermostat, label: "Feels", primaryColor: primaryColor),
                        _customButton(icon: Icons.location_on, label: "Earth", primaryColor: primaryColor),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search or type URL",
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () {},
                    child: const Text("Search", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Search With", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _searchEngineButton("Google", Icons.g_mobiledata, primaryColor, textColor),
                      _searchEngineButton("Duck", Icons.bubble_chart, primaryColor, textColor),
                      _searchEngineButton("Bing", Icons.brightness_5, primaryColor, textColor),
                      _searchEngineButton("Brave", Icons.shield, primaryColor, textColor),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _iconButton(Icons.ondemand_video, primaryColor),
                  _iconButton(Icons.email_outlined, primaryColor),
                  _iconButton(Icons.send, primaryColor),
                  _iconButton(Icons.call, primaryColor),
                  _iconButton(Icons.message, primaryColor),
                  _iconButton(Icons.videogame_asset, primaryColor),
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

  Widget _customButton({required IconData icon, required String label, required Color primaryColor}) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: primaryColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: primaryColor)),
        ],
      ),
    );
  }

  Widget _searchEngineButton(String label, IconData icon, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      radius: 22,
      child: Icon(icon, color: color, size: 20),
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

  const HomeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: onPressed,
    );
  }
}