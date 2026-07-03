// lib/models/chart_data.dart
import 'dart:ui';

import 'enums.dart';

class ChartData {
  final ChartType type;
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  ChartData({
    required this.type,
    required this.values,
    required this.labels,
    required this.colors,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      type: ChartType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChartType.bar,
      ),
      values: (json['values'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      labels: (json['labels'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      colors: (json['colors'] as List<dynamic>? ?? [])
          .map((e) => Color(e as int))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'values': values,
      'labels': labels,
      'colors': colors.map((color) => color.toARGB32()).toList(),
    };
  }
}
