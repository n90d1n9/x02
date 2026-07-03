import 'dart:math' as math;

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_named_range.dart';

part 'sheet_formula_functions.dart';
part 'sheet_formula_parser.dart';

class SheetFormulaEngine {
  const SheetFormulaEngine();

  String evaluate(
    String formula,
    Map<CellAddress, CellData> cells, {
    List<SheetNamedRange> namedRanges = const [],
  }) {
    final source = formula.startsWith('=') ? formula.substring(1) : formula;
    if (source.trim().isEmpty) return '';

    try {
      final context = _FormulaContext(cells, namedRanges);
      final tokens = _FormulaTokenizer(source).scan();
      return _FormulaParser(tokens, context).parse().format();
    } on _FormulaException catch (error) {
      return error.code;
    } catch (_) {
      return '#ERROR';
    }
  }
}

class _FormulaContext {
  _FormulaContext(this.cells, List<SheetNamedRange> namedRanges)
    : namedRangesByName = {
        for (final range in namedRanges) range.normalizedName: range,
      };

  final Map<CellAddress, CellData> cells;
  final Map<String, SheetNamedRange> namedRangesByName;

  _FormulaValue cellValue(CellAddress address) {
    final value = cells[address]?.value ?? '';
    if (value.isEmpty) return _FormulaValue.blank();
    if (value.startsWith('#')) return _FormulaValue.error(value);
    return _FormulaValue.text(value);
  }

  CellAddress parseAddress(String input) {
    final match = RegExp(
      r'^\$?([A-Za-z]+)\$?([0-9]+)$',
    ).firstMatch(input.trim());
    if (match == null) throw const _FormulaException('#REF');

    final columnLabel = match.group(1)!.toUpperCase();
    var column = 0;
    for (var index = 0; index < columnLabel.length; index++) {
      column = column * 26 + (columnLabel.codeUnitAt(index) - 64);
    }

    return CellAddress(int.parse(match.group(2)!) - 1, column - 1);
  }

  bool isAddress(String input) {
    return RegExp(r'^\$?[A-Za-z]+\$?[0-9]+$').hasMatch(input.trim());
  }

  List<CellAddress>? namedRangeAddresses(String input) {
    final range =
        namedRangesByName[SheetNamedRange.normalizeName(input).toLowerCase()];
    if (range == null) return null;

    return rangeAddresses(
      range.selection.start,
      range.selection.end ?? range.selection.start,
    );
  }

  List<CellAddress> rangeAddresses(CellAddress start, CellAddress end) {
    final minRow = math.min(start.row, end.row);
    final maxRow = math.max(start.row, end.row);
    final minCol = math.min(start.col, end.col);
    final maxCol = math.max(start.col, end.col);

    return [
      for (var row = minRow; row <= maxRow; row++)
        for (var col = minCol; col <= maxCol; col++) CellAddress(row, col),
    ];
  }
}

enum _FormulaValueKind { blank, number, text, boolean, range, error }

class _FormulaValue {
  const _FormulaValue._({
    required this.kind,
    this.number,
    this.text,
    this.boolean,
    this.range,
    this.decimalPlaces,
  });

  factory _FormulaValue.blank() {
    return const _FormulaValue._(kind: _FormulaValueKind.blank);
  }

  factory _FormulaValue.number(double value, {int? decimalPlaces}) {
    return _FormulaValue._(
      kind: _FormulaValueKind.number,
      number: value,
      decimalPlaces: decimalPlaces,
    );
  }

  factory _FormulaValue.text(String value) {
    return _FormulaValue._(kind: _FormulaValueKind.text, text: value);
  }

  factory _FormulaValue.boolean(bool value) {
    return _FormulaValue._(kind: _FormulaValueKind.boolean, boolean: value);
  }

  factory _FormulaValue.range(List<CellAddress> addresses) {
    return _FormulaValue._(kind: _FormulaValueKind.range, range: addresses);
  }

  factory _FormulaValue.error(String code) {
    return _FormulaValue._(kind: _FormulaValueKind.error, text: code);
  }

  final _FormulaValueKind kind;
  final double? number;
  final String? text;
  final bool? boolean;
  final List<CellAddress>? range;
  final int? decimalPlaces;

  bool get isBlank => kind == _FormulaValueKind.blank;
  bool get isError => kind == _FormulaValueKind.error;

  double asNumber(_FormulaContext context) {
    switch (kind) {
      case _FormulaValueKind.blank:
        return 0;
      case _FormulaValueKind.number:
        return number!;
      case _FormulaValueKind.text:
        final parsed = double.tryParse(text!.trim());
        if (parsed != null) return parsed;
        throw const _FormulaException('#VALUE');
      case _FormulaValueKind.boolean:
        return boolean! ? 1 : 0;
      case _FormulaValueKind.range:
        throw const _FormulaException('#VALUE');
      case _FormulaValueKind.error:
        throw _FormulaException(text!);
    }
  }

  double? asOptionalNumber(_FormulaContext context) {
    if (isBlank) return null;
    try {
      return asNumber(context);
    } on _FormulaException {
      return null;
    }
  }

  String asText(_FormulaContext context) {
    switch (kind) {
      case _FormulaValueKind.blank:
        return '';
      case _FormulaValueKind.number:
        return _compactNumber(number!);
      case _FormulaValueKind.text:
      case _FormulaValueKind.error:
        return text!;
      case _FormulaValueKind.boolean:
        return boolean! ? 'TRUE' : 'FALSE';
      case _FormulaValueKind.range:
        return range!
            .map((address) => context.cellValue(address).asText(context))
            .join();
    }
  }

  bool asBool(_FormulaContext context) {
    switch (kind) {
      case _FormulaValueKind.blank:
        return false;
      case _FormulaValueKind.number:
        return number != 0;
      case _FormulaValueKind.text:
        final normalized = text!.trim().toUpperCase();
        if (normalized == 'TRUE') return true;
        if (normalized == 'FALSE' || normalized.isEmpty) return false;
        final parsed = double.tryParse(normalized);
        return parsed != null ? parsed != 0 : true;
      case _FormulaValueKind.boolean:
        return boolean!;
      case _FormulaValueKind.range:
        throw const _FormulaException('#VALUE');
      case _FormulaValueKind.error:
        throw _FormulaException(text!);
    }
  }

  String format() {
    switch (kind) {
      case _FormulaValueKind.blank:
        return '';
      case _FormulaValueKind.number:
        final places = decimalPlaces;
        return places == null
            ? _compactNumber(number!)
            : number!.toStringAsFixed(places);
      case _FormulaValueKind.text:
      case _FormulaValueKind.error:
        return text!;
      case _FormulaValueKind.boolean:
        return boolean! ? 'TRUE' : 'FALSE';
      case _FormulaValueKind.range:
        return '#VALUE';
    }
  }

  static String _compactNumber(double value) {
    if (value.isNaN || value.isInfinite) return '#NUM';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _FormulaException implements Exception {
  const _FormulaException(this.code);

  final String code;
}
