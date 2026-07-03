import 'cell/cell_address.dart';

enum SheetChartType { bar, line, pie }

class SheetChartSpec {
  const SheetChartSpec({
    this.type = SheetChartType.bar,
    this.useFirstRowAsHeaders = true,
    this.useFirstColumnAsLabels = true,
  });

  final SheetChartType type;
  final bool useFirstRowAsHeaders;
  final bool useFirstColumnAsLabels;

  SheetChartSpec copyWith({
    SheetChartType? type,
    bool? useFirstRowAsHeaders,
    bool? useFirstColumnAsLabels,
  }) {
    return SheetChartSpec(
      type: type ?? this.type,
      useFirstRowAsHeaders: useFirstRowAsHeaders ?? this.useFirstRowAsHeaders,
      useFirstColumnAsLabels:
          useFirstColumnAsLabels ?? this.useFirstColumnAsLabels,
    );
  }

  String get typeLabel {
    return switch (type) {
      SheetChartType.bar => 'Bar',
      SheetChartType.line => 'Line',
      SheetChartType.pie => 'Pie',
    };
  }
}

class SheetChartData {
  const SheetChartData({required this.selectionLabel, this.series = const []});

  final String selectionLabel;
  final List<SheetChartSeries> series;

  bool get hasData => series.any((series) => series.points.isNotEmpty);

  int get pointCount {
    return series.fold(0, (sum, series) => sum + series.points.length);
  }

  double get maxValue {
    final values = [
      for (final chartSeries in series)
        for (final point in chartSeries.points) point.value,
    ];
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  List<SheetChartPoint> get primaryPoints {
    return series.isEmpty ? const [] : series.first.points;
  }
}

class SheetChartSeries {
  const SheetChartSeries({required this.label, required this.points});

  final String label;
  final List<SheetChartPoint> points;
}

class SheetChartPoint {
  const SheetChartPoint({
    required this.label,
    required this.value,
    this.address,
  });

  final String label;
  final double value;
  final CellAddress? address;
}
