import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/enums.dart';
import 'bar_chart_painter.dart';
import 'chart/line_chart_painter.dart';
import 'chart/pie_chart_painter.dart';

class SimpleChartWidget extends StatelessWidget {
  final ChartData data;

  const SimpleChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (data.type) {
      case ChartType.bar:
        return CustomPaint(painter: BarChartPainter(data));
      case ChartType.line:
        return CustomPaint(painter: LineChartPainter(data));
      case ChartType.pie:
        return CustomPaint(painter: PieChartPainter(data));
      default:
        return const Center(child: Icon(Icons.show_chart));
    }
  }
}
