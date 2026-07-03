import '../model/sheet_formula_function.dart';
import '../model/sheet_formula_suggestion.dart';
import '../model/sheet_named_range.dart';

class SheetFormulaAutocompleteEdit {
  const SheetFormulaAutocompleteEdit({
    required this.text,
    required this.caretOffset,
  });

  final String text;
  final int caretOffset;
}

class SheetFormulaAutocomplete {
  const SheetFormulaAutocomplete._();

  static List<SheetFormulaSuggestion> suggestions(
    String input, {
    int? caretOffset,
    int limit = 6,
    List<SheetNamedRange> namedRanges = const [],
  }) {
    final fragment = _activeFragment(input, caretOffset: caretOffset);
    if (fragment == null) return const [];

    final matches = <SheetFormulaSuggestion>[
      for (final function in SheetFormulaCatalog.functions)
        SheetFormulaSuggestion.function(function),
      for (final range in namedRanges) SheetFormulaSuggestion.namedRange(range),
    ].where((suggestion) => suggestion.matches(fragment.text)).toList();

    matches.sort((left, right) {
      final rankComparison = left
          .rankFor(fragment.text)
          .compareTo(right.rankFor(fragment.text));
      if (rankComparison != 0) return rankComparison;

      final kindComparison = left.kind.index.compareTo(right.kind.index);
      if (kindComparison != 0) return kindComparison;

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return matches.take(limit).toList(growable: false);
  }

  static SheetFormulaAutocompleteEdit applySuggestion(
    String input,
    Object suggestion, {
    int? caretOffset,
  }) {
    final fragment = _activeFragment(input, caretOffset: caretOffset);
    final replacement = _insertionText(suggestion);
    if (fragment == null) {
      final text = input.startsWith('=')
          ? '$input$replacement'
          : '=$replacement';
      return SheetFormulaAutocompleteEdit(text: text, caretOffset: text.length);
    }

    final text =
        input.substring(0, fragment.start) +
        replacement +
        input.substring(fragment.end);

    return SheetFormulaAutocompleteEdit(
      text: text,
      caretOffset: fragment.start + replacement.length,
    );
  }

  static String _insertionText(Object suggestion) {
    if (suggestion is SheetFormulaSuggestion) return suggestion.insertionText;
    if (suggestion is SheetFormulaFunction) return suggestion.suggestionText;
    throw ArgumentError.value(
      suggestion,
      'suggestion',
      'Unsupported formula suggestion',
    );
  }

  static _FormulaFragment? _activeFragment(String input, {int? caretOffset}) {
    if (!input.startsWith('=')) return null;

    final offset = (caretOffset ?? input.length).clamp(0, input.length).toInt();
    if (offset == 0 || _insideQuotedText(input, offset)) return null;

    var start = offset;
    while (start > 1 && _isIdentifierPart(input.codeUnitAt(start - 1))) {
      start--;
    }

    final fragmentText = input.substring(start, offset);
    if (fragmentText.isEmpty && input.substring(0, offset).trim() != '=') {
      return null;
    }

    return _FormulaFragment(start: start, end: offset, text: fragmentText);
  }

  static bool _insideQuotedText(String input, int offset) {
    var quoted = false;
    for (var index = 0; index < offset; index++) {
      if (input.codeUnitAt(index) == 34) {
        quoted = !quoted;
      }
    }
    return quoted;
  }

  static bool _isIdentifierPart(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122) ||
        (codeUnit >= 48 && codeUnit <= 57) ||
        codeUnit == 95 ||
        codeUnit == 46;
  }
}

class _FormulaFragment {
  const _FormulaFragment({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}
