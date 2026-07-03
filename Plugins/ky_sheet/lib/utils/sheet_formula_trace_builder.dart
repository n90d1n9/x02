import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_audit.dart';

enum SheetFormulaTraceMode { references, dependents, all }

class SheetFormulaTraceBuilder {
  const SheetFormulaTraceBuilder._();

  static List<CellSelection> build(
    SheetFormulaAudit audit,
    SheetFormulaTraceMode mode,
  ) {
    return _uniqueSelections(switch (mode) {
      SheetFormulaTraceMode.references => _referenceSelections(audit),
      SheetFormulaTraceMode.dependents => _dependentSelections(audit),
      SheetFormulaTraceMode.all => [
        ..._referenceSelections(audit),
        ..._dependentSelections(audit),
      ],
    });
  }

  static List<CellSelection> _referenceSelections(SheetFormulaAudit audit) {
    return [for (final reference in audit.references) reference.selection];
  }

  static List<CellSelection> _dependentSelections(SheetFormulaAudit audit) {
    return [
      for (final dependent in audit.dependents)
        CellSelection.single(dependent.address),
    ];
  }

  static List<CellSelection> _uniqueSelections(Iterable<CellSelection> items) {
    final seen = <String>{};
    return [
      for (final selection in items)
        if (seen.add(selection.label)) selection,
    ];
  }
}
