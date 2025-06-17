// lib/pages/splash_screen.dart
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
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _dotsController;

  bool showContinueButton = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Timer(Duration(seconds: 4), () {
      _navigateToHome();
    });

    Timer(Duration(seconds: 6), () {
      setState(() {
        showContinueButton = true;
      });
    });

    _dotsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat();

  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BrowserHomePage(
          onThemeToggle: widget.onThemeToggle,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _animation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/salate.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        "Salate",
                        style: TextStyle(
                          fontFamily: 'Sansita',
                          fontSize: screenWidth * 0.15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 1000),
                        child: Text(
                          "Fast. Private. Yours.",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            //fontFamily: 'Dancing Script',
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (index) {
                              final delay = index * 0.2;
                              final value = (_dotsController.value - delay) % 1.0;
                              final scale = 0.7 + 0.3 * (1.0 - (value * 2 - 1).abs().clamp(0.0, 1.0));
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.025),
                      if (showContinueButton)
                        TextButton(
                          onPressed: _navigateToHome,
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _animation,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Text(
                  "By Akshay Salate",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
