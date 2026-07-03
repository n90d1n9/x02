enum SheetFormulaIssueSortMode { cell, code }

extension SheetFormulaIssueSortModeLabel on SheetFormulaIssueSortMode {
  String get label => switch (this) {
    SheetFormulaIssueSortMode.cell => 'Cell',
    SheetFormulaIssueSortMode.code => 'Type',
  };
}
