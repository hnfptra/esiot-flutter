import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/mqtt_provider.dart';
import '../widgets/glass_bottom_nav.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_snackbar.dart';
import 'analytics_tab.dart';
import 'dashboard_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  int _seenDisconnects = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MqttProvider>();
      _seenDisconnects = provider.disconnectEvents;
      provider.addListener(_onConnectionChanged);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _tryReconnect();
  }

  Future<void> _tryReconnect() async {
    final success = await context.read<MqttProvider>().reconnectIfNeeded();
    if (!mounted || success) return;
    GlassSnackbar.show(
        context, 'Koneksi belum pulih. Periksa jaringan dan broker.',
        error: true);
  }

  void _onConnectionChanged() {
    final events = context.read<MqttProvider>().disconnectEvents;
    if (events > _seenDisconnects) {
      _seenDisconnects = events;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          GlassSnackbar.show(
              context, 'Koneksi terputus, mencoba menyambung kembali...');
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<MqttProvider>().removeListener(_onConnectionChanged);
    super.dispose();
  }

  Future<void> _disconnect() async {
    await context.read<MqttProvider>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MqttProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Monitor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: provider.isConnected
                        ? const Color(0xFF37B879)
                        : const Color(0xFFE9A13A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(provider.isConnected ? 'Live' : 'Offline',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Putuskan koneksi',
            onPressed: _disconnect,
            icon: const Icon(Icons.power_settings_new_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _index == 0
              ? const DashboardTab(key: ValueKey('dashboard'))
              : const AnalyticsTab(key: ValueKey('analytics')),
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        index: _index,
        onChanged: (value) {
          setState(() => _index = value);
          if (value == 1) context.read<HistoryProvider>().load();
        },
      ),
    );
  }
}
