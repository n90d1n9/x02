import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_named_range.dart';

class SheetFormulaReference {
  const SheetFormulaReference._();

  static final RegExp _cellReferencePattern = RegExp(
    r'(?<![A-Za-z0-9_])(\$?)([A-Za-z]+)(\$?)([0-9]+)(?![A-Za-z0-9_])',
  );
  static final RegExp _rangeReferencePattern = RegExp(
    r'(?<![A-Za-z0-9_])(\$?[A-Za-z]+\$?[0-9]+)(?:\s*:\s*(\$?[A-Za-z]+\$?[0-9]+))?(?![A-Za-z0-9_])',
  );
  static final RegExp _identifierPattern = RegExp(
    r'(?<![A-Za-z0-9_.])([A-Za-z_][A-Za-z0-9_.]*)(?![A-Za-z0-9_.])',
  );

  static String shiftFormula(
    String formula, {
    required int rowDelta,
    required int colDelta,
  }) {
    if (rowDelta == 0 && colDelta == 0) return formula;

    final buffer = StringBuffer();
    var inString = false;
    var segmentStart = 0;

    for (var index = 0; index < formula.length; index++) {
      if (formula[index] != '"') continue;

      if (!inString) {
        buffer.write(
          _shiftReferenceSegment(
            formula.substring(segmentStart, index),
            rowDelta: rowDelta,
            colDelta: colDelta,
          ),
        );
        segmentStart = index;
        inString = true;
      } else {
        buffer.write(formula.substring(segmentStart, index + 1));
        segmentStart = index + 1;
        inString = false;
      }
    }

    final tail = formula.substring(segmentStart);
    buffer.write(
      inString
          ? tail
          : _shiftReferenceSegment(
              tail,
              rowDelta: rowDelta,
              colDelta: colDelta,
            ),
    );

    return buffer.toString();
  }

  static List<CellSelection> referencedSelections(
    String formula, {
    List<SheetNamedRange> namedRanges = const [],
  }) {
    if (!formula.startsWith('=')) return const [];

    final namedRangesByName = {
      for (final range in namedRanges) range.normalizedName: range,
    };
    final selections = <CellSelection>[];
    _forEachUnquotedSegment(formula, (segment) {
      for (final match in _rangeReferencePattern.allMatches(segment)) {
        final start = _parseCellAddress(match.group(1)!);
        final endRef = match.group(2);
        selections.add(
          CellSelection(
            start,
            endRef == null ? null : _parseCellAddress(endRef),
          ),
        );
      }

      if (namedRangesByName.isEmpty) return;
      for (final match in _identifierPattern.allMatches(segment)) {
        if (_isFunctionCall(segment, match.end)) continue;

        final range =
            namedRangesByName[SheetNamedRange.normalizeName(
              match.group(1)!,
            ).toLowerCase()];
        if (range != null) selections.add(range.selection);
      }
    });

    return selections;
  }

  static bool _isFunctionCall(String segment, int endOffset) {
    var offset = endOffset;
    while (offset < segment.length && segment.codeUnitAt(offset) == 32) {
      offset++;
    }
    return offset < segment.length && segment[offset] == '(';
  }

  static String _shiftReferenceSegment(
    String segment, {
    required int rowDelta,
    required int colDelta,
  }) {
    return segment.replaceAllMapped(_cellReferencePattern, (match) {
      final absoluteCol = match.group(1) == r'$';
      final columnLabel = match.group(2)!;
      final absoluteRow = match.group(3) == r'$';
      final rowNumber = int.parse(match.group(4)!);

      final nextCol = absoluteCol
          ? _columnIndex(columnLabel)
          : (_columnIndex(columnLabel) + colDelta).clamp(0, 16383).toInt();
      final nextRow = absoluteRow
          ? rowNumber
          : (rowNumber + rowDelta).clamp(1, 1048576).toInt();

      return '${absoluteCol ? r'$' : ''}${CellAddress.colToLabel(nextCol)}'
          '${absoluteRow ? r'$' : ''}$nextRow';
    });
  }

  static void _forEachUnquotedSegment(
    String formula,
    void Function(String segment) visit,
  ) {
    var inString = false;
    var segmentStart = 0;

    for (var index = 0; index < formula.length; index++) {
      if (formula[index] != '"') continue;

      if (!inString) {
        visit(formula.substring(segmentStart, index));
        segmentStart = index;
        inString = true;
      } else {
        segmentStart = index + 1;
        inString = false;
      }
    }

    if (!inString) {
      visit(formula.substring(segmentStart));
    }
  }

  static CellAddress _parseCellAddress(String reference) {
    final normalized = reference.replaceAll(r'$', '');
    final match = RegExp(r'^([A-Za-z]+)([0-9]+)$').firstMatch(normalized);
    if (match == null) {
      throw FormatException('Invalid cell reference: $reference');
    }

    return CellAddress(
      int.parse(match.group(2)!) - 1,
      _columnIndex(match.group(1)!),
    );
  }

  static int _columnIndex(String label) {
    var column = 0;
    final upperLabel = label.toUpperCase();
    for (var i = 0; i < upperLabel.length; i++) {
      column = column * 26 + (upperLabel.codeUnitAt(i) - 64);
    }
    return column - 1;
  }
}
