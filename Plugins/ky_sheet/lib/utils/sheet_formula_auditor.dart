import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_audit.dart';
import '../model/sheet_named_range.dart';
import 'sheet_formula_reference.dart';

class SheetFormulaAuditor {
  const SheetFormulaAuditor._();

  static SheetFormulaAudit inspect({
    required CellSelection? selection,
    required Map<CellAddress, CellData> cells,
    required List<SheetNamedRange> namedRanges,
  }) {
    final address = selection?.start;
    final cellData = address == null ? null : cells[address];
    final formula = cellData?.formula ?? '';

    return SheetFormulaAudit(
      selection: selection,
      address: address,
      formula: formula,
      result: cellData?.value ?? '',
      references: _referencesFor(formula, namedRanges),
      dependents: _dependentsFor(
        selection: selection,
        cells: cells,
        namedRanges: namedRanges,
        ignoredAddress: address,
      ),
    );
  }

  static List<SheetFormulaAuditReference> _referencesFor(
    String formula,
    List<SheetNamedRange> namedRanges,
  ) {
    return [
      for (final selection in _uniqueSelections(
        SheetFormulaReference.referencedSelections(
          formula,
          namedRanges: namedRanges,
        ),
      ))
        SheetFormulaAuditReference(selection: selection),
    ];
  }

  static List<SheetFormulaAuditDependent> _dependentsFor({
    required CellSelection? selection,
    required Map<CellAddress, CellData> cells,
    required List<SheetNamedRange> namedRanges,
    required CellAddress? ignoredAddress,
  }) {
    if (selection == null) return const [];

    final dependents = <SheetFormulaAuditDependent>[];
    for (final entry in cells.entries) {
      final formula = entry.value.formula;
      if (formula == null || formula.isEmpty || entry.key == ignoredAddress) {
        continue;
      }

      final references = SheetFormulaReference.referencedSelections(
        formula,
        namedRanges: namedRanges,
      );
      final matches = [
        for (final reference in references)
          if (_overlaps(selection, reference)) reference,
      ];
      if (matches.isEmpty) continue;

      dependents.add(
        SheetFormulaAuditDependent(
          address: entry.key,
          formula: formula,
          result: entry.value.value,
          matchedReferences: _uniqueSelections(matches),
        ),
      );
    }

    dependents.sort((left, right) {
      final rowComparison = left.address.row.compareTo(right.address.row);
      return rowComparison == 0
          ? left.address.col.compareTo(right.address.col)
          : rowComparison;
    });

    return dependents;
  }

  static List<CellSelection> _uniqueSelections(Iterable<CellSelection> items) {
    final seen = <String>{};
    return [
      for (final selection in items)
        if (seen.add(selection.label)) selection,
    ];
  }

  static bool _overlaps(CellSelection left, CellSelection right) {
    return left.minRow <= right.maxRow &&
        left.maxRow >= right.minRow &&
        left.minCol <= right.maxCol &&
        left.maxCol >= right.minCol;
  }
}
