import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [Color(0xFF0B1020), Color(0xFF1A1033)]
                    : const [Color(0xFFEAF2FF), Color(0xFFF6EEFF)],
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                return Stack(
                  children: [
                    _blob(
                      top: -70 + 90 * math.sin(value * math.pi),
                      left: -60 + 70 * math.cos(value * math.pi),
                      color: const Color(0xFF4FD1C5),
                      size: 300,
                    ),
                    _blob(
                      top: 180 + 65 * math.cos(value * math.pi),
                      right: -100 + 50 * math.sin(value * math.pi),
                      color: const Color(0xFF9F7AEA),
                      size: 340,
                    ),
                    _blob(
                      bottom: -120 + 55 * math.sin(value * math.pi),
                      left: 50 + 70 * math.cos(value * math.pi),
                      color: const Color(0xFFF6AD55),
                      size: 310,
                    ),
                  ],
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required Color color,
    required double size,
  }) =>
      Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: .48),
                  color.withValues(alpha: 0)
                ],
              ),
            ),
          ),
        ),
      );
}
