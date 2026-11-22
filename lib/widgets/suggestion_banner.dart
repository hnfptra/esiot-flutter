import 'package:flutter/material.dart';

import '../logic/suggestion_engine.dart';
import 'glass_container.dart';

class SuggestionBanner extends StatelessWidget {
  const SuggestionBanner(
      {super.key, required this.temperature, required this.humidity});
  final double? temperature;
  final double? humidity;

  @override
  Widget build(BuildContext context) {
    final suggestions = evaluate(temperature, humidity);
    final primary = suggestions.first;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .04), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: GlassContainer(
        key: ValueKey(suggestions.map((item) => item.message).join('|')),
        tint: primary.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final suggestion in suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(suggestion.icon, color: suggestion.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(suggestion.message)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
