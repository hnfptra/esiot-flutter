class SensorData {
  const SensorData({
    this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  final int? id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  factory SensorData.fromMap(Map<String, Object?> map) => SensorData(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp']! as String),
        temperature: (map['temperature']! as num).toDouble(),
        humidity: (map['humidity']! as num).toDouble(),
      );

  Map<String, Object?> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'temperature': temperature,
        'humidity': humidity,
      };
}
