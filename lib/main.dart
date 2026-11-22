import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/mqtt_provider.dart';
import 'screens/connection_screen.dart';
import 'screens/main_shell.dart';
import 'services/database_service.dart';
import 'services/mqtt_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = DatabaseService();
  await database.initialize();
  final settings = SettingsService();
  final initialSettings = await settings.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MqttProvider(
            mqttService: MqttService(),
            database: database,
            settingsService: settings,
            initialSettings: initialSettings,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(database)..load(),
        ),
      ],
      child: const IoTMonitorApp(),
    ),
  );
}

class IoTMonitorApp extends StatelessWidget {
  const IoTMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final hasSession = context.select<MqttProvider, bool>(
      (provider) => provider.hasSession,
    );
    return GlassBackground(
      child: hasSession ? const MainShell() : const ConnectionScreen(),
    );
  }
}
