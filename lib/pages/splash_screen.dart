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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BrowserHomePage(
            onThemeToggle: widget.onThemeToggle,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: screen.width * 0.5,
                      height: screen.width * 0.5,
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
                        fontSize: screen.width * 0.15, // e.g. 36–48 on most screens
                        //fontWeight: FontWeight.bold,
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

                    // Dots for loading
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
                    )
                  ],
                ),
              ),
            ),
          ),

          // Footer
          FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: screen.height * 0.03,
              ),
              child: Text(
                "By Akshay Salate",
                style: TextStyle(
                  fontSize: screen.width * 0.035,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
