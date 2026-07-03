import 'sheet_formula_function.dart';
import 'sheet_named_range.dart';

enum SheetFormulaSuggestionKind { function, namedRange }

class SheetFormulaSuggestion {
  const SheetFormulaSuggestion.function(this.function)
    : kind = SheetFormulaSuggestionKind.function,
      namedRange = null;

  const SheetFormulaSuggestion.namedRange(this.namedRange)
    : kind = SheetFormulaSuggestionKind.namedRange,
      function = null;

  final SheetFormulaSuggestionKind kind;
  final SheetFormulaFunction? function;
  final SheetNamedRange? namedRange;

  String get name {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.name,
      SheetFormulaSuggestionKind.namedRange => namedRange!.name,
    };
  }

  String get signature {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.signature,
      SheetFormulaSuggestionKind.namedRange => namedRange!.selection.label,
    };
  }

  String get description {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.description,
      SheetFormulaSuggestionKind.namedRange =>
        'Named range ${namedRange!.selection.label}',
    };
  }

  String get category {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.category,
      SheetFormulaSuggestionKind.namedRange => 'Range',
    };
  }

  String get insertionText {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.suggestionText,
      SheetFormulaSuggestionKind.namedRange => namedRange!.name,
    };
  }

  bool matches(String query) {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.matches(query),
      SheetFormulaSuggestionKind.namedRange => _matchesNamedRange(query),
    };
  }

  int rankFor(String query) {
    return switch (kind) {
      SheetFormulaSuggestionKind.function => function!.rankFor(query),
      SheetFormulaSuggestionKind.namedRange => _namedRangeRank(query),
    };
  }

  bool _matchesNamedRange(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return namedRange!.name.toLowerCase().contains(normalized) ||
        namedRange!.selection.label.toLowerCase().contains(normalized);
  }

  int _namedRangeRank(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return 1;
    final name = namedRange!.name.toLowerCase();
    if (name == normalized) return 0;
    if (name.startsWith(normalized)) return 1;
    if (name.contains(normalized)) return 2;
    if (namedRange!.selection.label.toLowerCase().contains(normalized)) {
      return 3;
    }
    return 4;
  }
}
