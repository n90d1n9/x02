import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import 'sheet_formula_reference.dart';

enum FillDirection { up, down, left, right }

class SheetFillSeries {
  const SheetFillSeries._();

  static Map<CellAddress, CellData> buildFill({
    required CellSelection sourceSelection,
    required CellSelection targetSelection,
    required Map<CellAddress, CellData> cells,
  }) {
    final direction = _directionFor(sourceSelection, targetSelection);
    if (direction == null) return {};

    return switch (direction) {
      FillDirection.down || FillDirection.up => _buildVerticalFill(
        sourceSelection: sourceSelection,
        targetSelection: targetSelection,
        cells: cells,
        direction: direction,
      ),
      FillDirection.right || FillDirection.left => _buildHorizontalFill(
        sourceSelection: sourceSelection,
        targetSelection: targetSelection,
        cells: cells,
        direction: direction,
      ),
    };
  }

  static FillDirection? _directionFor(
    CellSelection source,
    CellSelection target,
  ) {
    if (target.minCol == source.minCol &&
        target.maxCol == source.maxCol &&
        target.maxRow > source.maxRow) {
      return FillDirection.down;
    }
    if (target.minCol == source.minCol &&
        target.maxCol == source.maxCol &&
        target.minRow < source.minRow) {
      return FillDirection.up;
    }
    if (target.minRow == source.minRow &&
        target.maxRow == source.maxRow &&
        target.maxCol > source.maxCol) {
      return FillDirection.right;
    }
    if (target.minRow == source.minRow &&
        target.maxRow == source.maxRow &&
        target.minCol < source.minCol) {
      return FillDirection.left;
    }
    return null;
  }

  static Map<CellAddress, CellData> _buildVerticalFill({
    required CellSelection sourceSelection,
    required CellSelection targetSelection,
    required Map<CellAddress, CellData> cells,
    required FillDirection direction,
  }) {
    final filled = <CellAddress, CellData>{};
    final sourceHeight = sourceSelection.maxRow - sourceSelection.minRow + 1;
    final fillStart = direction == FillDirection.down
        ? sourceSelection.maxRow + 1
        : targetSelection.minRow;
    final fillEnd = direction == FillDirection.down
        ? targetSelection.maxRow
        : sourceSelection.minRow - 1;

    for (
      var col = sourceSelection.minCol;
      col <= sourceSelection.maxCol;
      col++
    ) {
      final sourceCells = [
        for (
          var row = sourceSelection.minRow;
          row <= sourceSelection.maxRow;
          row++
        )
          (
            address: CellAddress(row, col),
            cell: cells[CellAddress(row, col)] ?? CellData(),
          ),
      ];
      final numericSeries = _numericSeries(
        sourceCells.map((source) => source.cell).toList(),
      );

      for (var row = fillStart; row <= fillEnd; row++) {
        final distance = direction == FillDirection.down
            ? row - sourceSelection.maxRow
            : sourceSelection.minRow - row;
        final sourceIndex = (distance - 1) % sourceHeight;
        final source = sourceCells[sourceIndex];
        final sourceCell = source.cell;
        final targetAddress = CellAddress(row, col);

        if (sourceCell.formula != null) {
          filled[targetAddress] = _shiftFormulaCell(
            sourceCell: sourceCell,
            sourceAddress: source.address,
            targetAddress: targetAddress,
          );
          continue;
        }

        final value = numericSeries == null
            ? sourceCell.value
            : _projectNumericValue(
                numericSeries: numericSeries,
                distance: distance,
                direction: direction,
              );

        filled[targetAddress] = sourceCell.copyWith(
          value: value,
          clearFormula: sourceCell.formula == null,
        );
      }
    }

    return filled;
  }

  static Map<CellAddress, CellData> _buildHorizontalFill({
    required CellSelection sourceSelection,
    required CellSelection targetSelection,
    required Map<CellAddress, CellData> cells,
    required FillDirection direction,
  }) {
    final filled = <CellAddress, CellData>{};
    final sourceWidth = sourceSelection.maxCol - sourceSelection.minCol + 1;
    final fillStart = direction == FillDirection.right
        ? sourceSelection.maxCol + 1
        : targetSelection.minCol;
    final fillEnd = direction == FillDirection.right
        ? targetSelection.maxCol
        : sourceSelection.minCol - 1;

    for (
      var row = sourceSelection.minRow;
      row <= sourceSelection.maxRow;
      row++
    ) {
      final sourceCells = [
        for (
          var col = sourceSelection.minCol;
          col <= sourceSelection.maxCol;
          col++
        )
          (
            address: CellAddress(row, col),
            cell: cells[CellAddress(row, col)] ?? CellData(),
          ),
      ];
      final numericSeries = _numericSeries(
        sourceCells.map((source) => source.cell).toList(),
      );

      for (var col = fillStart; col <= fillEnd; col++) {
        final distance = direction == FillDirection.right
            ? col - sourceSelection.maxCol
            : sourceSelection.minCol - col;
        final sourceIndex = (distance - 1) % sourceWidth;
        final source = sourceCells[sourceIndex];
        final sourceCell = source.cell;
        final targetAddress = CellAddress(row, col);

        if (sourceCell.formula != null) {
          filled[targetAddress] = _shiftFormulaCell(
            sourceCell: sourceCell,
            sourceAddress: source.address,
            targetAddress: targetAddress,
          );
          continue;
        }

        final value = numericSeries == null
            ? sourceCell.value
            : _projectNumericValue(
                numericSeries: numericSeries,
                distance: distance,
                direction: direction,
              );

        filled[targetAddress] = sourceCell.copyWith(
          value: value,
          clearFormula: sourceCell.formula == null,
        );
      }
    }

    return filled;
  }

  static _NumericSeries? _numericSeries(List<CellData> sourceCells) {
    if (sourceCells.any((cell) => cell.formula != null)) return null;

    final values = sourceCells
        .map((cell) => double.tryParse(cell.value.trim()))
        .toList();
    if (values.any((value) => value == null)) return null;

    final numericValues = values.cast<double>();
    final step = numericValues.length >= 2
        ? numericValues.last - numericValues[numericValues.length - 2]
        : 0.0;
    return _NumericSeries(
      last: numericValues.last,
      first: numericValues.first,
      step: step,
    );
  }

  static String _projectNumericValue({
    required _NumericSeries numericSeries,
    required int distance,
    required FillDirection direction,
  }) {
    final value = switch (direction) {
      FillDirection.down || FillDirection.right =>
        numericSeries.last + (numericSeries.step * distance),
      FillDirection.up || FillDirection.left =>
        numericSeries.first - (numericSeries.step * distance),
    };

    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  static CellData _shiftFormulaCell({
    required CellData sourceCell,
    required CellAddress sourceAddress,
    required CellAddress targetAddress,
  }) {
    final formula = sourceCell.formula;
    if (formula == null) return sourceCell;

    return sourceCell.copyWith(
      value: '',
      formula: SheetFormulaReference.shiftFormula(
        formula,
        rowDelta: targetAddress.row - sourceAddress.row,
        colDelta: targetAddress.col - sourceAddress.col,
      ),
    );
  }
}

class _NumericSeries {
  final double first;
  final double last;
  final double step;

  const _NumericSeries({
    required this.first,
    required this.last,
    required this.step,
  });
}
