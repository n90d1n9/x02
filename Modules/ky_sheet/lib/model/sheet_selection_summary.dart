import 'package:intl/intl.dart';

import 'cell/cell_address.dart';
import 'cell/cell_data.dart';
import 'cell/cell_selection.dart';

class SheetSelectionSummary {
  SheetSelectionSummary({
    required this.label,
    required this.selectedCellCount,
    required this.nonEmptyCellCount,
    required this.numericCellCount,
    required this.sum,
    this.min,
    this.max,
  });

  final String label;
  final int selectedCellCount;
  final int nonEmptyCellCount;
  final int numericCellCount;
  final double sum;
  final double? min;
  final double? max;

  static final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'en_US');

  bool get hasNumericValues => numericCellCount > 0;

  double? get average => numericCellCount == 0 ? null : sum / numericCellCount;

  factory SheetSelectionSummary.fromSelection({
    required CellSelection selection,
    required Map<CellAddress, CellData> cells,
  }) {
    var nonEmptyCellCount = 0;
    var numericCellCount = 0;
    var sum = 0.0;
    double? min;
    double? max;

    for (final address in selection.getCells()) {
      final value = cells[address]?.value.trim();
      if (value == null || value.isEmpty) continue;

      nonEmptyCellCount++;
      final numericValue = double.tryParse(value);
      if (numericValue == null) continue;

      numericCellCount++;
      sum += numericValue;
      min = min == null || numericValue < min ? numericValue : min;
      max = max == null || numericValue > max ? numericValue : max;
    }

    return SheetSelectionSummary(
      label: selection.label,
      selectedCellCount: selection.cellCount,
      nonEmptyCellCount: nonEmptyCellCount,
      numericCellCount: numericCellCount,
      sum: sum,
      min: min,
      max: max,
    );
  }

  static String formatNumber(double value) {
    if (!value.isFinite) return value.toString();
    return _numberFormat.format(value == -0 ? 0 : value);
  }
}
