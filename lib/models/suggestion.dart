import 'package:flutter/material.dart';

enum Severity { danger, warning, info, good, neutral }

class Suggestion {
  const Suggestion({
    required this.severity,
    required this.message,
    required this.icon,
  });

  final Severity severity;
  final String message;
  final IconData icon;

  Color get color => switch (severity) {
        Severity.danger => const Color(0xFFE6535D),
        Severity.warning => const Color(0xFFE9A13A),
        Severity.info => const Color(0xFF4387C8),
        Severity.good => const Color(0xFF35A77A),
        Severity.neutral => const Color(0xFF7C8798),
      };
}
