import 'package:flutter/material.dart';

import 'chart_type.dart';

class ChartData {
  final String id;
  final ChartType type;
  final String title;
  final List<String> labels;
  final List<double> values;
  final Color color;
  const ChartData({
    required this.id,
    required this.type,
    required this.title,
    required this.labels,
    required this.values,
    this.color = Colors.blue,
  });

  ChartData copyWith({
    String? id,
    ChartType? type,
    String? title,
    List<String>? labels,
    List<double>? values,
    Color? color,
  }) {
    return ChartData(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      labels: labels ?? this.labels,
      values: values ?? this.values,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'title': title,
    'labels': labels,
    'values': values,
    'color': color.toARGB32(),
  };
  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
    id: json['id'],
    type: ChartType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => ChartType.bar,
    ),
    title: json['title'],
    labels: List<String>.from(json['labels']),
    values: List<double>.from(json['values']),
    color: Color(json['color']),
  );
}
