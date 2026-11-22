import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mqtt_settings.dart';

class SettingsService {
  static const _prefix = 'mqtt.';
  static const _passwordKey = 'mqtt.password';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<MqttSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getBool('${_prefix}configured') ?? false;
    return MqttSettings(
      host: preferences.getString('${_prefix}host') ?? 'broker.emqx.io',
      port: preferences.getInt('${_prefix}port') ?? 1883,
      username: preferences.getString('${_prefix}username') ?? 'emqx',
      password: saved ? await _storage.read(key: _passwordKey) ?? '' : 'public',
      clientId: preferences.getString('${_prefix}clientId'),
      temperatureTopic: preferences.getString('${_prefix}temperatureTopic') ??
          'polines/data/2015041003/sensor/suhu',
      humidityTopic: preferences.getString('${_prefix}humidityTopic') ??
          'polines/data/2015041003/sensor/humidity',
      ledTopic: preferences.getString('${_prefix}ledTopic') ??
          'polines/data/2015041003/led',
      rememberMe: saved,
    );
  }

  Future<void> save(MqttSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    if (!settings.rememberMe) {
      for (final key in [
        'configured',
        'host',
        'port',
        'username',
        'clientId',
        'temperatureTopic',
        'humidityTopic',
        'ledTopic',
      ]) {
        await preferences.remove('$_prefix$key');
      }
      await _storage.delete(key: _passwordKey);
      return;
    }

    await preferences.setBool('${_prefix}configured', true);
    await preferences.setString('${_prefix}host', settings.host);
    await preferences.setInt('${_prefix}port', settings.port);
    await preferences.setString('${_prefix}username', settings.username);
    await preferences.setString('${_prefix}clientId', settings.clientId);
    await preferences.setString(
      '${_prefix}temperatureTopic',
      settings.temperatureTopic,
    );
    await preferences.setString(
        '${_prefix}humidityTopic', settings.humidityTopic);
    await preferences.setString('${_prefix}ledTopic', settings.ledTopic);
    await _storage.write(key: _passwordKey, value: settings.password);
  }
}
