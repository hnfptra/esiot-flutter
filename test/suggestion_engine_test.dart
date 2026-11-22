import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_iot_dashboard/logic/suggestion_engine.dart';
import 'package:mqtt_iot_dashboard/models/suggestion.dart';

void main() {
  group('evaluate', () {
    test('returns a neutral suggestion before any sensor data arrives', () {
      final suggestions = evaluate(null, null);

      expect(suggestions, hasLength(1));
      expect(suggestions.single.severity, Severity.neutral);
      expect(suggestions.single.message, 'Menunggu data sensor...');
    });

    test('applies inclusive comfortable and ideal boundaries', () {
      expect(evaluate(20, 40).map((item) => item.severity), [
        Severity.good,
        Severity.good,
      ]);
      expect(evaluate(30, 60).map((item) => item.severity), [
        Severity.good,
        Severity.good,
      ]);
    });

    test('evaluates each available reading and orders more severe first', () {
      final suggestions = evaluate(36, 82);

      expect(suggestions.map((item) => item.severity), [
        Severity.danger,
        Severity.warning,
      ]);
      expect(suggestions.first.message, contains('sangat panas'));
      expect(suggestions.last.message, contains('sangat tinggi'));
    });
  });
}
