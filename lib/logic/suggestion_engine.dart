import 'package:flutter/material.dart';

import '../models/suggestion.dart';

const temperatureColdThreshold = 16.0;
const temperatureComfortLow = 20.0;
const temperatureComfortHigh = 30.0;
const temperatureHotThreshold = 35.0;
const humidityLowThreshold = 30.0;
const humidityDryThreshold = 40.0;
const humidityIdealHigh = 60.0;
const humidityHighThreshold = 75.0;

List<Suggestion> evaluate(double? temperature, double? humidity) {
  if (temperature == null && humidity == null) {
    return const [
      Suggestion(
        severity: Severity.neutral,
        message: 'Menunggu data sensor...',
        icon: Icons.hourglass_empty_rounded,
      ),
    ];
  }

  final suggestions = <Suggestion>[];
  if (temperature != null) {
    if (temperature < temperatureColdThreshold) {
      suggestions.add(Suggestion(
        severity: Severity.warning,
        message:
            'Suhu ${_number(temperature)}°C sangat dingin. Hindari paparan langsung dan gunakan penghangat bila diperlukan.',
        icon: Icons.thermostat_rounded,
      ));
    } else if (temperature < temperatureComfortLow) {
      suggestions.add(Suggestion(
        severity: Severity.info,
        message: 'Suhu ${_number(temperature)}°C cukup dingin.',
        icon: Icons.info_outline_rounded,
      ));
    } else if (temperature <= temperatureComfortHigh) {
      suggestions.add(Suggestion(
        severity: Severity.good,
        message: 'Suhu ${_number(temperature)}°C berada pada rentang nyaman.',
        icon: Icons.check_circle_outline_rounded,
      ));
    } else if (temperature <= temperatureHotThreshold) {
      suggestions.add(Suggestion(
        severity: Severity.warning,
        message:
            'Suhu ${_number(temperature)}°C cukup panas. Pertimbangkan menyalakan kipas atau AC.',
        icon: Icons.thermostat_rounded,
      ));
    } else {
      suggestions.add(Suggestion(
        severity: Severity.danger,
        message:
            'Suhu ${_number(temperature)}°C sangat panas! Segera dinginkan ruangan dan pastikan hidrasi.',
        icon: Icons.warning_rounded,
      ));
    }
  }

  if (humidity != null) {
    if (humidity < humidityLowThreshold) {
      suggestions.add(Suggestion(
        severity: Severity.warning,
        message:
            'Kelembapan ${_number(humidity)}% sangat rendah. Gunakan humidifier atau tambahkan tanaman.',
        icon: Icons.water_drop_rounded,
      ));
    } else if (humidity < humidityDryThreshold) {
      suggestions.add(Suggestion(
        severity: Severity.info,
        message: 'Kelembapan ${_number(humidity)}% agak kering.',
        icon: Icons.water_drop_rounded,
      ));
    } else if (humidity <= humidityIdealHigh) {
      suggestions.add(Suggestion(
        severity: Severity.good,
        message: 'Kelembapan ${_number(humidity)}% ideal.',
        icon: Icons.water_drop_rounded,
      ));
    } else if (humidity <= humidityHighThreshold) {
      suggestions.add(Suggestion(
        severity: Severity.info,
        message:
            'Kelembapan ${_number(humidity)}% agak lembap. Pastikan sirkulasi udara baik.',
        icon: Icons.water_drop_rounded,
      ));
    } else {
      suggestions.add(Suggestion(
        severity: Severity.warning,
        message:
            'Kelembapan ${_number(humidity)}% sangat tinggi. Nyalakan dehumidifier dan periksa sirkulasi udara.',
        icon: Icons.water_drop_rounded,
      ));
    }
  }

  suggestions.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return suggestions;
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
