import 'package:flutter/material.dart';
import 'dart:async';
import 'package:salate_browser/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeInController;
  late AnimationController _fadeOutController;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  bool _startFadeOut = false;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOutController);

    _fadeInController.forward();

    Timer(const Duration(seconds: 3), () {
      setState(() => _startFadeOut = true);
      _fadeOutController.forward();

      Timer(const Duration(milliseconds: 900), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BrowserHomePage(
              onThemeToggle: widget.onThemeToggle,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: FadeTransition(
        opacity: _startFadeOut ? _fadeOut : _fadeIn,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: screen.width * 0.4,
                      height: screen.width * 0.4,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/salate_logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    SizedBox(height: screen.height * 0.015),

                    // Title
                    Text(
                      "Salate",
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: screen.width * 0.13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: screen.height * 0.01),

                    // Tagline
                    Text(
                      "Fast. Private. Yours.",
                      style: TextStyle(
                        fontSize: screen.width * 0.045,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: screen.height * 0.03),

                    // Dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: screen.width * 0.01),
                          width: screen.width * 0.025,
                          height: screen.width * 0.025,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(index == 1 ? 1.0 : 0.3),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: screen.height * 0.03),
              child: Text(
                "By Akshay Salate",
                style: TextStyle(
                  fontSize: screen.width * 0.035,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
