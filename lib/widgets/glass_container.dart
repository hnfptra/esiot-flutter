import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.blur = 24,
    this.tint,
    this.padding = const EdgeInsets.all(20),
    this.opacity = .18,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final VoidCallback? onTap;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const white = Colors.white;
    final baseTop =
        dark ? .10 : (widget.opacity + .10).clamp(0.0, 1.0).toDouble();
    final baseBottom =
        dark ? .04 : (widget.opacity - .06).clamp(0.0, 1.0).toDouble();
    final content = RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    white.withValues(alpha: baseTop),
                    (widget.tint ?? white).withValues(
                        alpha: widget.tint == null ? baseBottom : .12),
                  ],
                ),
                border: Border.all(
                  color: white.withValues(alpha: dark ? .20 : .54),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              white.withValues(alpha: dark ? .07 : .18),
                              white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                      padding: widget.padding ?? EdgeInsets.zero,
                      child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.onTap == null) return content;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: content,
      ),
    );
  }
}
