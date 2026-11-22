import 'package:flutter/foundation.dart';

import '../models/sensor_data.dart';
import '../services/database_service.dart';

enum HistoryRange { latest, day, week }

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._database);
  final DatabaseService _database;
  HistoryRange range = HistoryRange.latest;
  List<SensorData> points = [];
  bool loading = false;
  int recordCount = 0;
  double? _averageTemperature;
  double? _averageHumidity;

  double? get averageTemperature => _averageTemperature;
  double? get averageHumidity => _averageHumidity;

  Future<void> load([HistoryRange? nextRange]) async {
    if (nextRange != null) range = nextRange;
    loading = true;
    notifyListeners();
    try {
      if (range == HistoryRange.latest) {
        points = await _database.latest();
      } else {
        final duration = range == HistoryRange.day
            ? const Duration(hours: 24)
            : const Duration(days: 7);
        points = await _database.since(DateTime.now().subtract(duration));
      }
      recordCount = points.length;
      _averageTemperature = _average(points.map((point) => point.temperature));
      _averageHumidity = _average(points.map((point) => point.humidity));
      if (points.length > 300) {
        final step = (points.length / 300).ceil();
        points = [
          for (var index = 0; index < points.length; index += step)
            points[index],
          if ((points.length - 1) % step != 0) points.last,
        ];
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    await _database.clear();
    points = [];
    recordCount = 0;
    _averageTemperature = null;
    _averageHumidity = null;
    notifyListeners();
  }

  double? _average(Iterable<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
