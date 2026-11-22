import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/mqtt_settings.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';
import '../services/settings_service.dart';

class MqttProvider extends ChangeNotifier {
  MqttProvider({
    required MqttService mqttService,
    required DatabaseService database,
    required SettingsService settingsService,
    required MqttSettings initialSettings,
  })  : _mqttService = mqttService,
        _database = database,
        _settingsService = settingsService,
        settings = initialSettings {
    _mqttService
      ..onMessage = _handleMessage
      ..onDisconnected = _handleDisconnect
      ..onReconnected = _handleReconnect;
  }

  final MqttService _mqttService;
  final DatabaseService _database;
  final SettingsService _settingsService;
  MqttSettings settings;
  double? latestTemp;
  double? latestHum;
  bool ledOn = false;
  bool isConnected = false;
  bool hasSession = false;
  bool isConnecting = false;
  DateTime? lastDataAt;
  DateTime? lastLedCommandAt;
  int disconnectEvents = 0;
  Timer? _notifyTimer;
  bool _disposed = false;

  Future<void> connect(MqttSettings nextSettings) async {
    isConnecting = true;
    settings = nextSettings;
    notifyListeners();
    try {
      await _settingsService.save(nextSettings);
      await _mqttService.connect(nextSettings);
      isConnected = true;
      hasSession = true;
      latestTemp = null;
      latestHum = null;
      lastDataAt = null;
      _scheduleNotify();
    } finally {
      isConnecting = false;
      _scheduleNotify();
    }
  }

  void _handleMessage(String topic, String payload) {
    final value = double.tryParse(payload.trim());
    if (topic == settings.ledTopic) {
      if (payload.trim() == '1' || payload.trim() == '0') {
        ledOn = payload.trim() == '1';
        _scheduleNotify();
      }
      return;
    }
    if (value == null || !value.isFinite) return;
    if (topic == settings.temperatureTopic) {
      latestTemp = value;
    } else if (topic == settings.humidityTopic) {
      latestHum = value;
    } else {
      return;
    }
    lastDataAt = DateTime.now();
    final temperature = latestTemp;
    final humidity = latestHum;
    if (temperature != null && humidity != null) {
      unawaited(_database
          .insert(SensorData(
        timestamp: lastDataAt!,
        temperature: temperature,
        humidity: humidity,
      ))
          .catchError((Object error, StackTrace stackTrace) {
        developer.log('Could not store sensor reading',
            error: error, stackTrace: stackTrace);
      }));
    }
    _scheduleNotify();
  }

  void _handleDisconnect() {
    if (!isConnected || _disposed) return;
    isConnected = false;
    disconnectEvents++;
    _scheduleNotify();
  }

  void _handleReconnect() {
    if (_disposed) return;
    isConnected = true;
    _scheduleNotify();
  }

  void _scheduleNotify() {
    _notifyTimer ??= Timer(const Duration(milliseconds: 200), () {
      _notifyTimer = null;
      if (!_disposed) notifyListeners();
    });
  }

  void toggleLed(bool value) {
    _mqttService.publishLed(settings.ledTopic, value);
    ledOn = value;
    lastLedCommandAt = DateTime.now();
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _mqttService.disconnect();
    isConnected = false;
    hasSession = false;
    latestTemp = null;
    latestHum = null;
    lastDataAt = null;
    ledOn = false;
    notifyListeners();
  }

  Future<bool> reconnectIfNeeded() async {
    if (isConnected || isConnecting || !hasSession) return true;
    try {
      await connect(settings);
      return true;
    } catch (error, stackTrace) {
      developer.log('MQTT foreground reconnect failed',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    unawaited(_mqttService.disconnect());
    super.dispose();
  }
}
