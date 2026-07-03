import 'dart:math' as math;

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_go_to_special.dart';

class SheetGoToSpecialScanner {
  const SheetGoToSpecialScanner._();

  static SheetGoToSpecialResult scan({
    required SheetGoToSpecialKind kind,
    required Map<CellAddress, CellData> cells,
    int maxMatches = 250,
  }) {
    final usedRange = _usedRange(cells);
    final matches = <SheetGoToSpecialMatch>[];
    var totalCount = 0;

    void collect(SheetGoToSpecialMatch match) {
      totalCount++;
      if (matches.length < maxMatches) matches.add(match);
    }

    if (kind == SheetGoToSpecialKind.blanks) {
      if (usedRange != null) {
        for (var row = usedRange.minRow; row <= usedRange.maxRow; row++) {
          for (var col = usedRange.minCol; col <= usedRange.maxCol; col++) {
            final address = CellAddress(row, col);
            final cell = cells[address];
            if (cell == null || _isBlank(cell)) {
              collect(
                SheetGoToSpecialMatch(
                  address: address,
                  title: address.label,
                  detail: 'Blank cell',
                ),
              );
            }
          }
        }
      }
    } else {
      final entries = cells.entries.toList()
        ..sort((left, right) {
          final rowComparison = left.key.row.compareTo(right.key.row);
          return rowComparison == 0
              ? left.key.col.compareTo(right.key.col)
              : rowComparison;
        });

      for (final entry in entries) {
        final match = _matchFor(kind, entry.key, entry.value);
        if (match != null) collect(match);
      }
    }

    return SheetGoToSpecialResult(
      kind: kind,
      usedRangeLabel: usedRange?.label ?? 'None',
      totalCount: totalCount,
      matches: matches,
    );
  }

  static SheetGoToSpecialMatch? _matchFor(
    SheetGoToSpecialKind kind,
    CellAddress address,
    CellData cell,
  ) {
    return switch (kind) {
      SheetGoToSpecialKind.formulas =>
        _hasFormula(cell)
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: cell.formula!,
              )
            : null,
      SheetGoToSpecialKind.constants =>
        _isConstant(cell)
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: cell.value,
              )
            : null,
      SheetGoToSpecialKind.formulaErrors =>
        _hasFormula(cell) && cell.value.startsWith('#')
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: '${cell.value} ${cell.formula}',
              )
            : null,
      SheetGoToSpecialKind.comments =>
        _hasText(cell.comment)
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: cell.comment!.trim(),
              )
            : null,
      SheetGoToSpecialKind.hyperlinks =>
        _hasText(cell.hyperlink)
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: cell.hyperlink!.trim(),
              )
            : null,
      SheetGoToSpecialKind.validations =>
        cell.validation != null
            ? SheetGoToSpecialMatch(
                address: address,
                title: address.label,
                detail: cell.validation.toString(),
              )
            : null,
      SheetGoToSpecialKind.blanks => null,
    };
  }

  static CellSelection? _usedRange(Map<CellAddress, CellData> cells) {
    if (cells.isEmpty) return null;

    var minRow = cells.keys.first.row;
    var maxRow = minRow;
    var minCol = cells.keys.first.col;
    var maxCol = minCol;

    for (final address in cells.keys) {
      minRow = math.min(minRow, address.row);
      maxRow = math.max(maxRow, address.row);
      minCol = math.min(minCol, address.col);
      maxCol = math.max(maxCol, address.col);
    }

    return CellSelection(
      CellAddress(minRow, minCol),
      CellAddress(maxRow, maxCol),
    );
  }

  static bool _isConstant(CellData cell) {
    return !_hasFormula(cell) && cell.value.trim().isNotEmpty;
  }

  static bool _hasFormula(CellData cell) {
    return cell.formula?.trim().isNotEmpty ?? false;
  }

  static bool _isBlank(CellData cell) {
    return !_hasFormula(cell) &&
        cell.value.trim().isEmpty &&
        !_hasText(cell.comment) &&
        !_hasText(cell.hyperlink) &&
        cell.validation == null;
  }

  static bool _hasText(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }
}
