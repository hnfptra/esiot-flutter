import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_container.dart';

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav(
      {super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.paddingOf(context).bottom),
      child: GlassContainer(
        borderRadius: 32,
        padding: const EdgeInsets.all(7),
        child: SizedBox(
          height: 62,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                AnimatedAlign(
                  alignment:
                      index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: constraints.maxWidth / 2,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .38),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .55)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _item(context, 0, Icons.dashboard_rounded, 'Dashboard'),
                    _item(context, 1, Icons.analytics_rounded, 'Analitik'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int item, IconData icon, String label) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(item);
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 7),
                Text(label,
                    style: TextStyle(
                        fontWeight:
                            index == item ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
}
