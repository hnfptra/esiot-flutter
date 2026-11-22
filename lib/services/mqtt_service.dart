import 'dart:async';
import 'dart:developer' as developer;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/mqtt_settings.dart';

class MqttService {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
  void Function(String topic, String payload)? onMessage;
  void Function()? onDisconnected;
  void Function()? onReconnected;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect(MqttSettings settings) async {
    await disconnect();
    final client = MqttServerClient.withPort(
      settings.host,
      settings.clientId,
      settings.port,
    )
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..logging(on: false)
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(settings.clientId)
          .authenticateAs(settings.username, settings.password)
          .startClean();
    client.setProtocolV311();
    client.onDisconnected = () => onDisconnected?.call();
    client.onAutoReconnected = () => onReconnected?.call();
    _client = client;

    try {
      final status =
          await client.connect().timeout(const Duration(seconds: 10));
      if (status?.state != MqttConnectionState.connected) {
        throw StateError('MQTT broker menolak koneksi.');
      }
      _updates = client.updates?.listen((messages) {
        for (final message in messages) {
          final publish = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            publish.payload.message,
          );
          onMessage?.call(message.topic, payload);
        }
      });
      client.subscribe(settings.temperatureTopic, MqttQos.atMostOnce);
      client.subscribe(settings.humidityTopic, MqttQos.atMostOnce);
      client.subscribe(settings.ledTopic, MqttQos.atMostOnce);
    } on TimeoutException {
      client.disconnect();
      throw const MqttConnectionException('timeout');
    } catch (error, stackTrace) {
      developer.log('MQTT connection failed',
          error: error, stackTrace: stackTrace);
      client.disconnect();
      if (error is MqttConnectionException || error is StateError) rethrow;
      throw const MqttConnectionException('connection');
    }
  }

  void publishLed(String topic, bool isOn) {
    final client = _client;
    if (client == null || !isConnected) {
      throw StateError('MQTT client is not connected.');
    }
    final builder = MqttClientPayloadBuilder()..addString(isOn ? '1' : '0');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> disconnect() async {
    await _updates?.cancel();
    _updates = null;
    final client = _client;
    _client = null;
    client?.onDisconnected = null;
    client?.disconnect();
  }
}

class MqttConnectionException implements Exception {
  const MqttConnectionException(this.reason);
  final String reason;
}
