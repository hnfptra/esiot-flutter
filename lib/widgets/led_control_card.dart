import 'package:flutter/material.dart';

import 'glass_container.dart';

class LedControlCard extends StatelessWidget {
  const LedControlCard({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.lastCommandAt,
  });

  final bool isOn;
  final ValueChanged<bool> onChanged;
  final DateTime? lastCommandAt;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn
                  ? const Color(0xFFFFC857).withValues(alpha: .24)
                  : Colors.white.withValues(alpha: .20),
              shape: BoxShape.circle,
              boxShadow: isOn
                  ? [
                      BoxShadow(
                          color: const Color(0xFFFFC857).withValues(alpha: .48),
                          blurRadius: 18)
                    ]
                  : null,
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: isOn ? const Color(0xFFFFB928) : Colors.blueGrey,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kontrol LED',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  isOn ? 'LED menyala' : 'LED mati',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (lastCommandAt != null)
                  Text(
                    'Perintah ${TimeOfDay.fromDateTime(lastCommandAt!).format(context)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOn,
            activeTrackColor: const Color(0xFFE9A13A),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
