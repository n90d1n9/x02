import '../models/chart_data.dart';
import '../models/chart_type.dart';

class ChartInsertion {
  final ChartData chart;
  final List<ChartData> charts;

  const ChartInsertion({required this.chart, required this.charts});

  String get reference => '\n[CHART:${chart.id}]\n';
}

class DocumentChartService {
  const DocumentChartService();

  ChartInsertion insertChart({
    required List<ChartData> currentCharts,
    required String id,
    required ChartType type,
    required String title,
    required List<String> labels,
    required List<double> values,
  }) {
    final chart = ChartData(
      id: id,
      type: type,
      title: title,
      labels: List<String>.from(labels),
      values: List<double>.from(values),
    );

    return ChartInsertion(chart: chart, charts: [...currentCharts, chart]);
  }

  List<ChartData> updateChart({
    required List<ChartData> currentCharts,
    required String chartId,
    required String title,
    required List<String> labels,
    required List<double> values,
  }) {
    return currentCharts.map((chart) {
      if (chart.id != chartId) return chart;

      return chart.copyWith(
        title: title,
        labels: List<String>.from(labels),
        values: List<double>.from(values),
      );
    }).toList();
  }

  List<ChartData> deleteChart({
    required List<ChartData> currentCharts,
    required String chartId,
  }) {
    return currentCharts.where((chart) => chart.id != chartId).toList();
  }
}
