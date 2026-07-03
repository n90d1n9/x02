import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/chart_data.dart';
import 'package:ky_docs/docx/models/chart_type.dart';
import 'package:ky_docs/docx/services/document_chart_service.dart';

void main() {
  group('DocumentChartService', () {
    const service = DocumentChartService();

    test('inserts a chart with deterministic id and document reference', () {
      final insertion = service.insertChart(
        currentCharts: const [],
        id: 'chart-1',
        type: ChartType.bar,
        title: 'Revenue',
        labels: const ['Q1', 'Q2'],
        values: const [10, 20],
      );

      expect(insertion.reference, '\n[CHART:chart-1]\n');
      expect(insertion.chart.id, 'chart-1');
      expect(insertion.chart.type, ChartType.bar);
      expect(insertion.chart.title, 'Revenue');
      expect(insertion.chart.labels, ['Q1', 'Q2']);
      expect(insertion.chart.values, [10, 20]);
      expect(insertion.charts, [insertion.chart]);
    });

    test('copies incoming labels and values on insert', () {
      final labels = ['Q1'];
      final values = [10.0];
      final insertion = service.insertChart(
        currentCharts: const [],
        id: 'chart-1',
        type: ChartType.line,
        title: 'Trend',
        labels: labels,
        values: values,
      );

      labels[0] = 'Changed';
      values[0] = 99;

      expect(insertion.chart.labels, ['Q1']);
      expect(insertion.chart.values, [10]);
    });

    test(
      'updates title, labels, and values while preserving type and color',
      () {
        const chart = ChartData(
          id: 'chart-1',
          type: ChartType.pie,
          title: 'Old',
          labels: ['A'],
          values: [1],
          color: Colors.green,
        );

        final charts = service.updateChart(
          currentCharts: const [chart],
          chartId: 'chart-1',
          title: 'Updated',
          labels: const ['B', 'C'],
          values: const [2, 3],
        );

        expect(charts.single.type, ChartType.pie);
        expect(charts.single.color, Colors.green);
        expect(charts.single.title, 'Updated');
        expect(charts.single.labels, ['B', 'C']);
        expect(charts.single.values, [2, 3]);
      },
    );

    test('does not update non-matching charts', () {
      const chart = ChartData(
        id: 'chart-1',
        type: ChartType.doughnut,
        title: 'Original',
        labels: ['A'],
        values: [1],
      );

      final charts = service.updateChart(
        currentCharts: const [chart],
        chartId: 'missing',
        title: 'Updated',
        labels: const ['B'],
        values: const [2],
      );

      expect(charts.single, same(chart));
    });

    test('deletes a chart by id', () {
      const first = ChartData(
        id: 'chart-1',
        type: ChartType.bar,
        title: 'First',
        labels: ['A'],
        values: [1],
      );
      const second = ChartData(
        id: 'chart-2',
        type: ChartType.line,
        title: 'Second',
        labels: ['B'],
        values: [2],
      );

      final charts = service.deleteChart(
        currentCharts: const [first, second],
        chartId: 'chart-1',
      );

      expect(charts, const [second]);
    });
  });
}
