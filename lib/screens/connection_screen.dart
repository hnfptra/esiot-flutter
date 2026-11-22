import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mqtt_settings.dart';
import '../providers/mqtt_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_snackbar.dart';
import '../widgets/glass_text_field.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _clientId = TextEditingController();
  final _temperatureTopic = TextEditingController();
  final _humidityTopic = TextEditingController();
  final _ledTopic = TextEditingController();
  bool _remember = false;
  bool _hidePassword = true;
  bool _expandedTopics = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = context.read<MqttProvider>().settings;
    _host.text = settings.host;
    _port.text = settings.port.toString();
    _username.text = settings.username;
    _password.text = settings.password;
    _clientId.text = settings.clientId;
    _temperatureTopic.text = settings.temperatureTopic;
    _humidityTopic.text = settings.humidityTopic;
    _ledTopic.text = settings.ledTopic;
    _remember = settings.rememberMe;
    _initialized = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _host,
      _port,
      _username,
      _password,
      _clientId,
      _temperatureTopic,
      _humidityTopic,
      _ledTopic,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = MqttSettings(
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      password: _password.text,
      clientId: _clientId.text.trim(),
      temperatureTopic: _temperatureTopic.text.trim(),
      humidityTopic: _humidityTopic.text.trim(),
      ledTopic: _ledTopic.text.trim(),
      rememberMe: _remember,
    );
    try {
      await context.read<MqttProvider>().connect(settings);
    } catch (_) {
      if (!mounted) return;
      final message =
          'Tidak dapat terhubung. Periksa host, port, kredensial, dan jaringan.'
          '${Platform.isIOS ? ' Pastikan izin Jaringan Lokal diaktifkan di Pengaturan iOS.' : ''}';
      GlassSnackbar.show(context, message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MqttProvider>();
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sensors_rounded,
                    size: 44, color: Color(0xFF418F9A)),
                const SizedBox(height: 12),
                Text('IoT Monitor',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Hubungkan ke broker MQTT untuk mulai memantau sensor.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                GlassContainer(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _host,
                          label: 'Broker Host',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Host wajib diisi'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          controller: _port,
                          label: 'Port',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final port = int.tryParse(value ?? '');
                            return port == null || port < 1 || port > 65535
                                ? 'Port harus 1–65535'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                            controller: _username, label: 'Username'),
                        const SizedBox(height: 12),
                        GlassTextField(
                          controller: _password,
                          label: 'Password',
                          obscureText: _hidePassword,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                            controller: _clientId, label: 'Client ID'),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _remember,
                          title: const Text('Ingat pengaturan dan kata sandi'),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) =>
                              setState(() => _remember = value ?? false),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Pengaturan topik'),
                          initiallyExpanded: _expandedTopics,
                          onExpansionChanged: (value) =>
                              setState(() => _expandedTopics = value),
                          children: [
                            GlassTextField(
                                controller: _temperatureTopic,
                                label: 'Topik suhu'),
                            const SizedBox(height: 10),
                            GlassTextField(
                                controller: _humidityTopic,
                                label: 'Topik kelembapan'),
                            const SizedBox(height: 10),
                            GlassTextField(
                                controller: _ledTopic, label: 'Topik LED'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassButton(
                          label: 'Connect',
                          icon: Icons.power_rounded,
                          loading: provider.isConnecting,
                          onPressed: _connect,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Broker uji: broker.emqx.io • Port 1883',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
