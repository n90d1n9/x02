part of 'sheet_formula_engine.dart';

enum _FormulaTokenType { number, string, identifier, symbol, eof }

class _FormulaToken {
  const _FormulaToken(this.type, this.lexeme, this.position);

  final _FormulaTokenType type;
  final String lexeme;
  final int position;
}

class _FormulaTokenizer {
  _FormulaTokenizer(this.source);

  final String source;
  final List<_FormulaToken> _tokens = [];
  var _index = 0;

  List<_FormulaToken> scan() {
    while (!_isAtEnd) {
      final char = _advance();
      final position = _index - 1;

      if (char.trim().isEmpty) continue;

      if (_isDigit(char) || (char == '.' && _peekIsDigit())) {
        _scanNumber(position);
      } else if (char == '"') {
        _scanString(position);
      } else if (_isIdentifierStart(char)) {
        _scanIdentifier(position);
      } else {
        _scanSymbol(char, position);
      }
    }

    _tokens.add(_FormulaToken(_FormulaTokenType.eof, '', _index));
    return _tokens;
  }

  bool get _isAtEnd => _index >= source.length;

  String _advance() => source[_index++];

  String _peek() => _isAtEnd ? '\u0000' : source[_index];

  String _peekNext() =>
      _index + 1 >= source.length ? '\u0000' : source[_index + 1];

  bool _peekIsDigit() => _isDigit(_peek());

  void _scanNumber(int position) {
    while (_isDigit(_peek())) {
      _advance();
    }

    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance();
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    _tokens.add(
      _FormulaToken(
        _FormulaTokenType.number,
        source.substring(position, _index),
        position,
      ),
    );
  }

  void _scanString(int position) {
    final buffer = StringBuffer();

    while (!_isAtEnd) {
      final char = _advance();
      if (char == '"') {
        if (_peek() == '"') {
          _advance();
          buffer.write('"');
          continue;
        }

        _tokens.add(
          _FormulaToken(_FormulaTokenType.string, buffer.toString(), position),
        );
        return;
      }

      buffer.write(char);
    }

    throw const _FormulaException('#ERROR');
  }

  void _scanIdentifier(int position) {
    while (_isIdentifierPart(_peek())) {
      _advance();
    }

    _tokens.add(
      _FormulaToken(
        _FormulaTokenType.identifier,
        source.substring(position, _index),
        position,
      ),
    );
  }

  void _scanSymbol(String char, int position) {
    final next = _peek();
    final twoCharacterSymbol = switch ('$char$next') {
      '>=' || '<=' || '<>' || '!=' => true,
      _ => false,
    };

    if (twoCharacterSymbol) {
      _advance();
      _tokens.add(
        _FormulaToken(
          _FormulaTokenType.symbol,
          source.substring(position, _index),
          position,
        ),
      );
      return;
    }

    if ('+-*/^&(),:=<>%'.contains(char)) {
      _tokens.add(_FormulaToken(_FormulaTokenType.symbol, char, position));
      return;
    }

    throw const _FormulaException('#ERROR');
  }

  bool _isDigit(String char) {
    if (char.length != 1) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isIdentifierStart(String char) {
    if (char == r'$') return true;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isIdentifierPart(String char) {
    if (char == r'$' || char == '_' || char == '.') return true;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57);
  }
}

class _FormulaParser {
  _FormulaParser(this.tokens, this.context)
    : _functions = _FormulaFunctions(context);

  final List<_FormulaToken> tokens;
  final _FormulaContext context;
  final _FormulaFunctions _functions;
  var _current = 0;

  _FormulaValue parse() {
    final value = _comparison();
    if (!_isAtEnd) throw const _FormulaException('#ERROR');
    return value;
  }

  _FormulaValue _comparison() {
    var left = _concatenation();

    while (_matchAny(['>=', '<=', '<>', '!=', '=', '>', '<'])) {
      final operator = _previous.lexeme;
      final right = _concatenation();
      left = _FormulaValue.boolean(_compare(left, right, operator));
    }

    return left;
  }

  _FormulaValue _concatenation() {
    var left = _addition();

    while (_match('&')) {
      final right = _addition();
      left = _FormulaValue.text(left.asText(context) + right.asText(context));
    }

    return left;
  }

  _FormulaValue _addition() {
    var left = _multiplication();

    while (_matchAny(['+', '-'])) {
      final operator = _previous.lexeme;
      final right = _multiplication();
      final result = operator == '+'
          ? left.asNumber(context) + right.asNumber(context)
          : left.asNumber(context) - right.asNumber(context);
      left = _FormulaValue.number(result, decimalPlaces: 2);
    }

    return left;
  }

  _FormulaValue _multiplication() {
    var left = _power();

    while (_matchAny(['*', '/'])) {
      final operator = _previous.lexeme;
      final right = _power();
      final rightNumber = right.asNumber(context);

      if (operator == '/' && rightNumber == 0) {
        throw const _FormulaException('#DIV/0');
      }

      final result = operator == '*'
          ? left.asNumber(context) * rightNumber
          : left.asNumber(context) / rightNumber;
      left = _FormulaValue.number(result, decimalPlaces: 2);
    }

    return left;
  }

  _FormulaValue _power() {
    var left = _unary();

    if (_match('^')) {
      final right = _power();
      left = _FormulaValue.number(
        math.pow(left.asNumber(context), right.asNumber(context)).toDouble(),
        decimalPlaces: 2,
      );
    }

    return left;
  }

  _FormulaValue _unary() {
    if (_match('+')) return _unary();
    if (_match('-')) {
      return _FormulaValue.number(
        -_unary().asNumber(context),
        decimalPlaces: 2,
      );
    }

    return _postfix();
  }

  _FormulaValue _postfix() {
    var value = _primary();
    while (_match('%')) {
      value = _FormulaValue.number(
        value.asNumber(context) / 100,
        decimalPlaces: 2,
      );
    }
    return value;
  }

  _FormulaValue _primary() {
    if (_matchType(_FormulaTokenType.number)) {
      return _FormulaValue.number(
        double.parse(_previous.lexeme),
        decimalPlaces: 2,
      );
    }

    if (_matchType(_FormulaTokenType.string)) {
      return _FormulaValue.text(_previous.lexeme);
    }

    if (_matchType(_FormulaTokenType.identifier)) {
      return _identifierValue(_previous.lexeme);
    }

    if (_match('(')) {
      final value = _comparison();
      _consume(')');
      return value;
    }

    throw const _FormulaException('#ERROR');
  }

  _FormulaValue _identifierValue(String identifier) {
    final normalized = identifier.toUpperCase();

    if (_match('(')) {
      return _functions.call(normalized, _arguments());
    }

    if (normalized == 'TRUE') return _FormulaValue.boolean(true);
    if (normalized == 'FALSE') return _FormulaValue.boolean(false);

    if (context.isAddress(identifier)) {
      final start = context.parseAddress(identifier);
      if (_match(':')) {
        final endToken = _consumeType(_FormulaTokenType.identifier);
        if (!context.isAddress(endToken.lexeme)) {
          throw const _FormulaException('#REF');
        }
        return _FormulaValue.range(
          context.rangeAddresses(start, context.parseAddress(endToken.lexeme)),
        );
      }

      return context.cellValue(start);
    }

    final namedRange = context.namedRangeAddresses(identifier);
    if (namedRange != null) {
      if (namedRange.length == 1) return context.cellValue(namedRange.single);
      return _FormulaValue.range(namedRange);
    }

    throw const _FormulaException('#NAME');
  }

  List<_FormulaValue> _arguments() {
    final values = <_FormulaValue>[];
    if (_match(')')) return values;

    do {
      values.add(_comparison());
    } while (_match(','));

    _consume(')');
    return values;
  }

  bool _compare(_FormulaValue left, _FormulaValue right, String operator) {
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

  bool _match(String symbol) {
    if (!_check(symbol)) return false;
    _advance();
    return true;
  }

  bool _matchAny(List<String> symbols) {
    for (final symbol in symbols) {
      if (_check(symbol)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _matchType(_FormulaTokenType type) {
    if (_isAtEnd || _peek.type != type) return false;
    _advance();
    return true;
  }

  void _consume(String symbol) {
    if (_match(symbol)) return;
    throw const _FormulaException('#ERROR');
  }

  _FormulaToken _consumeType(_FormulaTokenType type) {
    if (_matchType(type)) return _previous;
    throw const _FormulaException('#ERROR');
  }

  bool _check(String symbol) {
    if (_isAtEnd) return false;
    return _peek.type == _FormulaTokenType.symbol && _peek.lexeme == symbol;
  }

  _FormulaToken _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  bool get _isAtEnd => _peek.type == _FormulaTokenType.eof;

  _FormulaToken get _peek => tokens[_current];

  _FormulaToken get _previous => tokens[_current - 1];
}
