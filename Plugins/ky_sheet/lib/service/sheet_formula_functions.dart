part of 'sheet_formula_engine.dart';

class _FormulaFunctions {
  const _FormulaFunctions(this.context);

  final _FormulaContext context;

  _FormulaValue call(String name, List<_FormulaValue> args) {
    return switch (name) {
      'SUM' => _sum(args),
      'AVG' || 'AVERAGE' => _average(args),
      'COUNT' => _count(args),
      'COUNTA' => _countA(args),
      'MIN' => _min(args),
      'MAX' => _max(args),
      'IF' => _if(args),
      'SUMIF' => _sumIf(args),
      'COUNTIF' => _countIf(args),
      'VLOOKUP' => _vLookup(args),
      'CONCAT' || 'CONCATENATE' => _concat(args),
      'LEN' => _length(args),
      'UPPER' => _upper(args),
      'LOWER' => _lower(args),
      'ROUND' => _round(args),
      'ABS' => _absolute(args),
      _ => throw const _FormulaException('#NAME'),
    };
  }

  _FormulaValue _sum(List<_FormulaValue> args) {
    return _FormulaValue.number(
      _numericValues(args).fold(0, (sum, value) => sum + value),
      decimalPlaces: 2,
    );
  }

  _FormulaValue _average(List<_FormulaValue> args) {
    final values = _numericValues(args).toList();
    if (values.isEmpty) return _FormulaValue.number(0, decimalPlaces: 2);
    return _FormulaValue.number(
      values.fold(0.0, (sum, value) => sum + value) / values.length,
      decimalPlaces: 2,
    );
  }

  _FormulaValue _count(List<_FormulaValue> args) {
    return _FormulaValue.number(_numericValues(args).length.toDouble());
  }

  _FormulaValue _countA(List<_FormulaValue> args) {
    var count = 0;
    for (final value in _expandedValues(args)) {
      if (!value.isBlank) count++;
    }
    return _FormulaValue.number(count.toDouble());
  }

  _FormulaValue _min(List<_FormulaValue> args) {
    final values = _numericValues(args).toList();
    if (values.isEmpty) return _FormulaValue.number(0, decimalPlaces: 2);
    return _FormulaValue.number(values.reduce(math.min), decimalPlaces: 2);
  }

  _FormulaValue _max(List<_FormulaValue> args) {
    final values = _numericValues(args).toList();
    if (values.isEmpty) return _FormulaValue.number(0, decimalPlaces: 2);
    return _FormulaValue.number(values.reduce(math.max), decimalPlaces: 2);
  }

  _FormulaValue _if(List<_FormulaValue> args) {
    if (args.length < 2 || args.length > 3) {
      throw const _FormulaException('#ERROR');
    }

    if (args[0].asBool(context)) return args[1];
    return args.length == 3 ? args[2] : _FormulaValue.blank();
  }

  _FormulaValue _sumIf(List<_FormulaValue> args) {
    if (args.length < 2 || args.length > 3) {
      throw const _FormulaException('#ERROR');
    }

    final criteriaRange = _asRange(args[0]);
    final sumRange = args.length == 3 ? _asRange(args[2]) : criteriaRange;
    var sum = 0.0;

    for (var index = 0; index < criteriaRange.length; index++) {
      if (_matchesCriteria(context.cellValue(criteriaRange[index]), args[1]) &&
          index < sumRange.length) {
        sum +=
            context.cellValue(sumRange[index]).asOptionalNumber(context) ?? 0;
      }
    }

    return _FormulaValue.number(sum, decimalPlaces: 2);
  }

  _FormulaValue _countIf(List<_FormulaValue> args) {
    if (args.length != 2) throw const _FormulaException('#ERROR');

    var count = 0;
    for (final address in _asRange(args[0])) {
      if (_matchesCriteria(context.cellValue(address), args[1])) count++;
    }

    return _FormulaValue.number(count.toDouble());
  }

  _FormulaValue _vLookup(List<_FormulaValue> args) {
    if (args.length < 3 || args.length > 4) {
      throw const _FormulaException('#ERROR');
    }

    final tableRange = _asRange(args[1]);
    if (tableRange.isEmpty) return _FormulaValue.error('#N/A');

    final columnIndex = args[2].asNumber(context).round();
    if (columnIndex < 1) return _FormulaValue.error('#REF');

    final minCol = tableRange.map((address) => address.col).reduce(math.min);
    final maxCol = tableRange.map((address) => address.col).reduce(math.max);
    final targetCol = minCol + columnIndex - 1;
    if (targetCol > maxCol) return _FormulaValue.error('#REF');

    final rows = tableRange.map((address) => address.row).toSet().toList()
      ..sort();
    for (final row in rows) {
      final firstColumnAddress = CellAddress(row, minCol);
      if (!tableRange.contains(firstColumnAddress)) continue;

      if (_valuesEqual(context.cellValue(firstColumnAddress), args[0])) {
        final targetAddress = CellAddress(row, targetCol);
        return tableRange.contains(targetAddress)
            ? context.cellValue(targetAddress)
            : _FormulaValue.error('#REF');
      }
    }

    return _FormulaValue.error('#N/A');
  }

  _FormulaValue _concat(List<_FormulaValue> args) {
    final buffer = StringBuffer();
    for (final value in _expandedValues(args)) {
      buffer.write(value.asText(context));
    }
    return _FormulaValue.text(buffer.toString());
  }

  _FormulaValue _length(List<_FormulaValue> args) {
    _expectArgCount(args, 1);
    return _FormulaValue.number(args.single.asText(context).length.toDouble());
  }

  _FormulaValue _upper(List<_FormulaValue> args) {
    _expectArgCount(args, 1);
    return _FormulaValue.text(args.single.asText(context).toUpperCase());
  }

  _FormulaValue _lower(List<_FormulaValue> args) {
    _expectArgCount(args, 1);
    return _FormulaValue.text(args.single.asText(context).toLowerCase());
  }

  _FormulaValue _round(List<_FormulaValue> args) {
    if (args.isEmpty || args.length > 2) {
      throw const _FormulaException('#ERROR');
    }

    final places = args.length == 2 ? args[1].asNumber(context).round() : 0;
    final factor = math.pow(10, places.abs()).toDouble();
    final value = args[0].asNumber(context);
    final rounded = places >= 0
        ? (value * factor).round() / factor
        : (value / factor).round() * factor;

    return _FormulaValue.number(
      rounded,
      decimalPlaces: places.clamp(0, 10).toInt(),
    );
  }

  _FormulaValue _absolute(List<_FormulaValue> args) {
    _expectArgCount(args, 1);
    return _FormulaValue.number(
      args.single.asNumber(context).abs(),
      decimalPlaces: 2,
    );
  }

  Iterable<double> _numericValues(List<_FormulaValue> args) sync* {
    for (final value in _expandedValues(args)) {
      final number = value.asOptionalNumber(context);
      if (number != null) yield number;
    }
  }

  Iterable<_FormulaValue> _expandedValues(List<_FormulaValue> args) sync* {
    for (final value in args) {
      if (value.kind == _FormulaValueKind.range) {
        for (final address in value.range!) {
          yield context.cellValue(address);
        }
      } else {
        yield value;
      }
    }
  }

  List<CellAddress> _asRange(_FormulaValue value) {
    if (value.kind != _FormulaValueKind.range) {
      throw const _FormulaException('#VALUE');
    }
    return value.range!;
  }

  bool _matchesCriteria(_FormulaValue candidate, _FormulaValue criteria) {
    final criteriaText = criteria.asText(context).trim();
    final match = RegExp(r'^(>=|<=|<>|!=|=|>|<)(.*)$').firstMatch(criteriaText);

    if (match != null) {
      final operator = match.group(1)!;
      final right = _FormulaValue.text(match.group(2)!.trim());
      return _compareByOperator(candidate, right, operator);
    }

    return _valuesEqual(candidate, criteria);
  }

  bool _compareByOperator(
    _FormulaValue left,
    _FormulaValue right,
    String operator,
  ) {
    final leftNumber = left.asOptionalNumber(context);
    final rightNumber = right.asOptionalNumber(context);

    if (leftNumber != null && rightNumber != null) {
      final comparison = leftNumber.compareTo(rightNumber);
      return switch (operator) {
        '>=' => comparison >= 0,
        '<=' => comparison <= 0,
        '>' => comparison > 0,
        '<' => comparison < 0,
        '=' => comparison == 0,
        '!=' || '<>' => comparison != 0,
        _ => false,
      };
    }

    final comparison = left
        .asText(context)
        .toLowerCase()
        .compareTo(right.asText(context).toLowerCase());
    return switch (operator) {
      '>=' => comparison >= 0,
      '<=' => comparison <= 0,
      '>' => comparison > 0,
      '<' => comparison < 0,
      '=' => comparison == 0,
      '!=' || '<>' => comparison != 0,
      _ => false,
    };
  }

  bool _valuesEqual(_FormulaValue left, _FormulaValue right) {
    final leftNumber = left.asOptionalNumber(context);
    final rightNumber = right.asOptionalNumber(context);
    if (leftNumber != null && rightNumber != null) {
      return leftNumber == rightNumber;
    }

    return left.asText(context).toLowerCase() ==
        right.asText(context).toLowerCase();
  }

  void _expectArgCount(List<_FormulaValue> args, int count) {
    if (args.length != count) throw const _FormulaException('#ERROR');
  }
}
