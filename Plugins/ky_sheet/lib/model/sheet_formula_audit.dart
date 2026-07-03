import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';

class SheetFormulaAudit {
  const SheetFormulaAudit({
    required this.selection,
    required this.address,
    required this.formula,
    required this.result,
    required this.references,
    required this.dependents,
  });

  final CellSelection? selection;
  final CellAddress? address;
  final String formula;
  final String result;
  final List<SheetFormulaAuditReference> references;
  final List<SheetFormulaAuditDependent> dependents;

  bool get hasSelection => selection != null;
  bool get hasFormula => formula.trim().isNotEmpty;
  String get selectionLabel => selection?.label ?? 'None';
  String get addressLabel => address?.label ?? 'None';
}

class SheetFormulaAuditReference {
  const SheetFormulaAuditReference({required this.selection});

  final CellSelection selection;

  String get label => selection.label;
}

class SheetFormulaAuditDependent {
  const SheetFormulaAuditDependent({
    required this.address,
    required this.formula,
    required this.result,
    required this.matchedReferences,
  });

  final CellAddress address;
  final String formula;
  final String result;
  final List<CellSelection> matchedReferences;

  String get label => address.label;
}
