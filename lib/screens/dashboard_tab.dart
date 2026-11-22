import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/mqtt_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_snackbar.dart';
import '../widgets/led_control_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/suggestion_banner.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MqttProvider>();
    final timestamp = provider.lastDataAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                provider.isConnected
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                color: provider.isConnected
                    ? const Color(0xFF35A77A)
                    : const Color(0xFFE9A13A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        provider.isConnected
                            ? 'Broker terhubung'
                            : 'Menunggu koneksi kembali',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${provider.settings.host}:${provider.settings.port}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Data terakhir',
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    timestamp == null
                        ? '—'
                        : DateFormat('HH:mm:ss').format(timestamp),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Kondisi ruangan',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 162,
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Suhu',
                  value: provider.latestTemp,
                  unit: '°C',
                  icon: Icons.thermostat_rounded,
                  tint: const Color(0xFFE99642),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Kelembapan',
                  value: provider.latestHum,
                  unit: '%',
                  icon: Icons.water_drop_rounded,
                  tint: const Color(0xFF4387C8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SuggestionBanner(
            temperature: provider.latestTemp, humidity: provider.latestHum),
        const SizedBox(height: 14),
        LedControlCard(
          isOn: provider.ledOn,
          lastCommandAt: provider.lastLedCommandAt,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            try {
              provider.toggleLed(value);
            } catch (_) {
              GlassSnackbar.show(context, 'Perintah LED gagal dikirim.',
                  error: true);
            }
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Riwayat tersimpan otomatis • ${timestamp == null ? 'menunggu data' : DateFormat('HH:mm').format(timestamp)}',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
