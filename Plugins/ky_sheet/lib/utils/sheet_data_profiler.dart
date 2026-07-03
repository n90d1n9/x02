import 'dart:math' as math;

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_data_profile.dart';
import '../model/sheet_selection_summary.dart';

class SheetDataProfiler {
  const SheetDataProfiler._();

  static SheetDataProfile profile({
    required CellSelection? selection,
    required Map<CellAddress, CellData> cells,
  }) {
    final effectiveSelection = selection ?? _usedRange(cells);
    if (effectiveSelection == null) {
      return const SheetDataProfile(
        label: 'No data',
        totalCells: 0,
        filledCells: 0,
        blankCells: 0,
        numericCells: 0,
        textCells: 0,
        formulaCells: 0,
        invalidCells: 0,
        duplicateValueCells: 0,
        sum: 0,
        fromSelection: false,
      );
    }

    var filledCells = 0;
    var numericCells = 0;
    var textCells = 0;
    var formulaCells = 0;
    var invalidCells = 0;
    var duplicateValueCells = 0;
    var sum = 0.0;
    double? min;
    double? max;
    final numericValues = <double>[];
    final frequencies = <String, _ValueFrequency>{};

    for (final address in effectiveSelection.getCells()) {
      final cell = cells[address];
      final rawValue = cell?.value.trim() ?? '';
      final hasFormula = cell?.formula != null;
      final isFilled = rawValue.isNotEmpty || hasFormula;

      if (!isFilled) continue;

      filledCells++;
      if (hasFormula) formulaCells++;

      final validation = cell?.validation;
      if (validation != null && !validation.validate(cell?.value ?? '')) {
        invalidCells++;
      }

      final numericValue = double.tryParse(rawValue);
      if (numericValue == null) {
        if (rawValue.isNotEmpty) textCells++;
      } else {
        numericCells++;
        numericValues.add(numericValue);
        sum += numericValue;
        min = min == null || numericValue < min ? numericValue : min;
        max = max == null || numericValue > max ? numericValue : max;
      }

      if (rawValue.isNotEmpty) {
        frequencies.update(
          rawValue,
          (frequency) => frequency.increment(),
          ifAbsent: () => _ValueFrequency(firstAddress: address),
        );
      }
    }

    duplicateValueCells = frequencies.values
        .where((frequency) => frequency.count > 1)
        .fold(0, (sum, frequency) => sum + frequency.count);

    return SheetDataProfile(
      label: effectiveSelection.label,
      totalCells: effectiveSelection.cellCount,
      filledCells: filledCells,
      blankCells: effectiveSelection.cellCount - filledCells,
      numericCells: numericCells,
      textCells: textCells,
      formulaCells: formulaCells,
      invalidCells: invalidCells,
      duplicateValueCells: duplicateValueCells,
      sum: sum,
      min: min,
      max: max,
      topValues: _topValues(frequencies),
      histogram: _histogram(numericValues),
      fromSelection: selection != null,
    );
  }

  static CellSelection? _usedRange(Map<CellAddress, CellData> cells) {
    final occupied = cells.entries
        .where(
          (entry) =>
              entry.value.value.trim().isNotEmpty ||
              entry.value.formula != null,
        )
        .map((entry) => entry.key)
        .toList();
    if (occupied.isEmpty) return null;

    final minRow = occupied.map((address) => address.row).reduce(math.min);
    final maxRow = occupied.map((address) => address.row).reduce(math.max);
    final minCol = occupied.map((address) => address.col).reduce(math.min);
    final maxCol = occupied.map((address) => address.col).reduce(math.max);

    return CellSelection(
      CellAddress(minRow, minCol),
      CellAddress(maxRow, maxCol),
    );
  }

  static List<SheetValueFrequency> _topValues(
    Map<String, _ValueFrequency> frequencies,
  ) {
    final values = [
      for (final entry in frequencies.entries)
        SheetValueFrequency(
          value: entry.key,
          count: entry.value.count,
          firstAddress: entry.value.firstAddress,
        ),
    ];
    values.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      return countCompare == 0 ? a.value.compareTo(b.value) : countCompare;
    });
    return values.take(5).toList(growable: false);
  }

  static List<SheetNumericBucket> _histogram(List<double> values) {
    if (values.isEmpty) return const [];

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    if (min == max) {
      return [
        SheetNumericBucket(label: _formatNumber(min), count: values.length),
      ];
    }

    final bucketCount = math.min(5, math.max(1, values.length)).toInt();
    final counts = List<int>.filled(bucketCount, 0);
    final width = (max - min) / bucketCount;

    for (final value in values) {
      final rawIndex = ((value - min) / width).floor();
      final index = rawIndex.clamp(0, bucketCount - 1).toInt();
      counts[index]++;
    }

    return [
      for (var index = 0; index < bucketCount; index++)
        SheetNumericBucket(
          label:
              '${_formatNumber(min + (width * index))}-${_formatNumber(index == bucketCount - 1 ? max : min + (width * (index + 1)))}',
          count: counts[index],
        ),
    ];
  }

  static String _formatNumber(double value) {
    return SheetSelectionSummary.formatNumber(value);
  }
}

class _ValueFrequency {
  const _ValueFrequency({required this.firstAddress, this.count = 1});

  final CellAddress firstAddress;
  final int count;

  _ValueFrequency increment() {
    return _ValueFrequency(firstAddress: firstAddress, count: count + 1);
  }
}
