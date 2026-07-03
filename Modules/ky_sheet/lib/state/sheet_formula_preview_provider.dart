import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_selection.dart';

enum SheetFormulaPreviewSource {
  formulaEdit,
  traceReferences,
  traceDependents,
  traceAll,
  formulaIssue,
  formulaIssues,
}

class SheetFormulaPreviewContext {
  const SheetFormulaPreviewContext({
    required this.source,
    required this.targetCount,
    this.originLabel,
  });

  final SheetFormulaPreviewSource source;
  final int targetCount;
  final String? originLabel;

  String get statusLabel {
    return switch (source) {
      SheetFormulaPreviewSource.formulaEdit => 'Formula Preview',
      SheetFormulaPreviewSource.traceReferences => 'Trace References',
      SheetFormulaPreviewSource.traceDependents => 'Trace Dependents',
      SheetFormulaPreviewSource.traceAll => 'Trace All',
      SheetFormulaPreviewSource.formulaIssue => 'Formula Issue',
      SheetFormulaPreviewSource.formulaIssues => 'Formula Issues',
    };
  }

  String get statusValue {
    final noun = targetCount == 1 ? 'range' : 'ranges';
    final countLabel = '$targetCount $noun';
    final origin = originLabel;
    if (origin == null || origin.isEmpty) return countLabel;
    return '$origin: $countLabel';
  }
}

final formulaReferencePreviewProvider = StateProvider<List<CellSelection>>(
  (ref) => const [],
);

final formulaReferencePreviewContextProvider =
    StateProvider<SheetFormulaPreviewContext?>((ref) => null);
