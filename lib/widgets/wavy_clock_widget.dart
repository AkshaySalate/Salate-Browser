import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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