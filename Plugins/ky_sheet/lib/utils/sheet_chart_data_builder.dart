import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_chart.dart';

class SheetChartDataBuilder {
  const SheetChartDataBuilder._();

  static SheetChartData build({
    required CellSelection? selection,
    required Map<CellAddress, CellData> cells,
    required SheetChartSpec spec,
  }) {
    if (selection == null) {
      return const SheetChartData(selectionLabel: 'No selection');
    }

    final rowCount = selection.maxRow - selection.minRow + 1;
    final columnCount = selection.maxCol - selection.minCol + 1;
    final hasHeaderRow = spec.useFirstRowAsHeaders && rowCount > 1;
    final hasLabelColumn = spec.useFirstColumnAsLabels && columnCount > 1;
    final firstDataRow = selection.minRow + (hasHeaderRow ? 1 : 0);
    final firstDataColumn = selection.minCol + (hasLabelColumn ? 1 : 0);

    if (firstDataRow > selection.maxRow || firstDataColumn > selection.maxCol) {
      return SheetChartData(selectionLabel: selection.label);
    }

    final categories = [
      for (var row = firstDataRow; row <= selection.maxRow; row++)
        _categoryLabel(
          cells: cells,
          row: row,
          labelColumn: hasLabelColumn ? selection.minCol : null,
        ),
    ];

    final series = <SheetChartSeries>[];
    for (var col = firstDataColumn; col <= selection.maxCol; col++) {
      final points = <SheetChartPoint>[];
      for (var row = firstDataRow; row <= selection.maxRow; row++) {
        final value = double.tryParse(
          cells[CellAddress(row, col)]?.value ?? '',
        );
        if (value == null) continue;

        points.add(
          SheetChartPoint(
            label: categories[row - firstDataRow],
            value: value,
            address: CellAddress(row, col),
          ),
        );
      }

      if (points.isEmpty) continue;
      series.add(
        SheetChartSeries(
          label: _seriesLabel(
            cells: cells,
            column: col,
            headerRow: hasHeaderRow ? selection.minRow : null,
          ),
          points: points,
        ),
      );
    }

    return SheetChartData(selectionLabel: selection.label, series: series);
  }

  static String _categoryLabel({
    required Map<CellAddress, CellData> cells,
    required int row,
    required int? labelColumn,
  }) {
    if (labelColumn != null) {
      final label = cells[CellAddress(row, labelColumn)]?.value.trim() ?? '';
      if (label.isNotEmpty) return label;
    }
    return 'Row ${row + 1}';
  }

  static String _seriesLabel({
    required Map<CellAddress, CellData> cells,
    required int column,
    required int? headerRow,
  }) {
    if (headerRow != null) {
      final label = cells[CellAddress(headerRow, column)]?.value.trim() ?? '';
      if (label.isNotEmpty) return label;
    }
    return CellAddress.colToLabel(column);
  }
}
