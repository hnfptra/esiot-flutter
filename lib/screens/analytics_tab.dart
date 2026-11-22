import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/sensor_chart.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Text('Analitik',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _rangeChip(context, history, HistoryRange.latest, '100 terbaru'),
            _rangeChip(context, history, HistoryRange.day, '24 jam'),
            _rangeChip(context, history, HistoryRange.week, '7 hari'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _stat(context, 'Rata-rata suhu',
                    history.averageTemperature, '°C')),
            const SizedBox(width: 10),
            Expanded(
                child: _stat(
                    context, 'Rata-rata RH', history.averageHumidity, '%')),
            const SizedBox(width: 10),
            Expanded(child: _count(context, history.recordCount)),
          ],
        ),
        const SizedBox(height: 14),
        if (history.loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          SensorChart(
            title: 'Suhu',
            unit: '°C',
            points: history.points,
            valueOf: (point) => point.temperature,
            color: const Color(0xFFE99642),
            icon: Icons.thermostat_rounded,
          ),
          const SizedBox(height: 14),
          SensorChart(
            title: 'Kelembapan',
            unit: '%',
            points: history.points,
            valueOf: (point) => point.humidity,
            color: const Color(0xFF4387C8),
            icon: Icons.water_drop_rounded,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: history.points.isEmpty
                  ? null
                  : () => _confirmClear(context, history),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus riwayat'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _rangeChip(
    BuildContext context,
    HistoryProvider history,
    HistoryRange range,
    String label,
  ) {
    final selected = history.range == range;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => history.load(range),
      selectedColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: .25),
      backgroundColor: Colors.white.withValues(alpha: .20),
      side: BorderSide(color: Colors.white.withValues(alpha: .45)),
    );
  }

  Widget _stat(BuildContext context, String label, double? value, String unit) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text(value == null ? '—' : '${value.toStringAsFixed(1)} $unit',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _count(BuildContext context, int count) => GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titik data', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 5),
            Text('$count',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Future<void> _confirmClear(
      BuildContext context, HistoryProvider history) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).colorScheme.surface.withValues(alpha: .94),
        title: const Text('Hapus riwayat?'),
        content:
            const Text('Semua data sensor tersimpan akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (clear == true) await history.clear();
  }
}
