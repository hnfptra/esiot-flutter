import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import 'glass_container.dart';

class SensorChart extends StatelessWidget {
  const SensorChart({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.valueOf,
    required this.color,
    required this.icon,
  });

  final String title;
  final String unit;
  final List<SensorData> points;
  final double Function(SensorData) valueOf;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final values = points.map(valueOf).toList();
    final minValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxValue =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final padding = mathPadding(minValue, maxValue);
    final low = minValue - padding;
    final high = maxValue + padding;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
              if (values.isNotEmpty)
                Text(
                  '${minValue.toStringAsFixed(1)}–${maxValue.toStringAsFixed(1)} $unit',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (points.isEmpty)
            const SizedBox(
              height: 190,
              child: Center(child: Text('Belum ada data')),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: low,
                  maxY: high,
                  minX: 0,
                  maxX:
                      (points.length - 1).toDouble().clamp(1, double.infinity),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: .25),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, _) => Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (points.length / 3).clamp(1, double.infinity),
                        getTitlesWidget: (value, _) {
                          final index = value.round();
                          return index >= 0 && index < points.length
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('HH:mm')
                                        .format(points[index].timestamp),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} $unit',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var index = 0; index < values.length; index++)
                          FlSpot(index.toDouble(), values[index]),
                      ],
                      isCurved: true,
                      curveSmoothness: .25,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: .28),
                            color.withValues(alpha: 0)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double mathPadding(double min, double max) {
    final difference = max - min;
    return difference == 0
        ? (max.abs() * .1).clamp(1, double.infinity)
        : difference * .1;
  }
}
