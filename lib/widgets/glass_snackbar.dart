import 'package:flutter/material.dart';

import 'glass_container.dart';

class GlassSnackbar {
  static void show(BuildContext context, String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          content: GlassContainer(
            borderRadius: 20,
            tint: error ? const Color(0xFF9D3941) : const Color(0xFF233952),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        ),
      );
  }
}
