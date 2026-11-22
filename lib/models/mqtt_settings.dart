import 'dart:math';

class MqttSettings {
  MqttSettings({
    this.host = 'broker.emqx.io',
    this.port = 1883,
    this.username = 'emqx',
    this.password = 'public',
    String? clientId,
    this.temperatureTopic = 'polines/data/2015041003/sensor/suhu',
    this.humidityTopic = 'polines/data/2015041003/sensor/humidity',
    this.ledTopic = 'polines/data/2015041003/led',
    this.rememberMe = false,
  }) : clientId = clientId ?? _newClientId();

  final String host;
  final int port;
  final String username;
  final String password;
  final String clientId;
  final String temperatureTopic;
  final String humidityTopic;
  final String ledTopic;
  final bool rememberMe;

  static String _newClientId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return 'flutter_${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  MqttSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? clientId,
    String? temperatureTopic,
    String? humidityTopic,
    String? ledTopic,
    bool? rememberMe,
  }) =>
      MqttSettings(
        host: host ?? this.host,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        clientId: clientId ?? this.clientId,
        temperatureTopic: temperatureTopic ?? this.temperatureTopic,
        humidityTopic: humidityTopic ?? this.humidityTopic,
        ledTopic: ledTopic ?? this.ledTopic,
        rememberMe: rememberMe ?? this.rememberMe,
      );
}
