/// Aggregate functions available from a structured table totals row.
enum SheetTableTotalFunction { sum, average, count, countA, min, max }

/// Common text labels for the leading cell in a table totals row.
enum SheetTableTotalLabelPreset { total, grandTotal, subtotal, summary }

/// Presentation and formula metadata for totals-row aggregate functions.
extension SheetTableTotalFunctionInfo on SheetTableTotalFunction {
  /// User-facing label shown in totals-row menus.
  String get label {
    return switch (this) {
      SheetTableTotalFunction.sum => 'Sum',
      SheetTableTotalFunction.average => 'Average',
      SheetTableTotalFunction.count => 'Count Numbers',
      SheetTableTotalFunction.countA => 'Count Values',
      SheetTableTotalFunction.min => 'Min',
      SheetTableTotalFunction.max => 'Max',
    };
  }

  /// Formula function name understood by the Ky Sheet formula engine.
  String get formulaName {
    return switch (this) {
      SheetTableTotalFunction.sum => 'SUM',
      SheetTableTotalFunction.average => 'AVERAGE',
      SheetTableTotalFunction.count => 'COUNT',
      SheetTableTotalFunction.countA => 'COUNTA',
      SheetTableTotalFunction.min => 'MIN',
      SheetTableTotalFunction.max => 'MAX',
    };
  }
}

/// Presentation metadata for totals-row label presets.
extension SheetTableTotalLabelPresetInfo on SheetTableTotalLabelPreset {
  /// User-facing label inserted into the totals row.
  String get label {
    return switch (this) {
      SheetTableTotalLabelPreset.total => 'Total',
      SheetTableTotalLabelPreset.grandTotal => 'Grand Total',
      SheetTableTotalLabelPreset.subtotal => 'Subtotal',
      SheetTableTotalLabelPreset.summary => 'Summary',
    };
  }
}
