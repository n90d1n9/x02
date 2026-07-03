import 'cell/cell_address.dart';

enum SheetSearchScope { cellValues, formulas, all }

enum SheetSearchTarget { value, formula }

class SheetSearchOptions {
  const SheetSearchOptions({
    this.matchCase = false,
    this.scope = SheetSearchScope.cellValues,
  });

  final bool matchCase;
  final SheetSearchScope scope;

  bool get includeValues => scope != SheetSearchScope.formulas;
  bool get includeFormulas => scope != SheetSearchScope.cellValues;
}

class SheetSearchMatch {
  const SheetSearchMatch({
    required this.address,
    required this.target,
    required this.text,
    required this.start,
    required this.end,
  });

  final CellAddress address;
  final SheetSearchTarget target;
  final String text;
  final int start;
  final int end;

  String get targetLabel {
    return switch (target) {
      SheetSearchTarget.value => 'Value',
      SheetSearchTarget.formula => 'Formula',
    };
  }

  String get matchedText => text.substring(start, end);

  @override
  bool operator ==(Object other) {
    return other is SheetSearchMatch &&
        other.address == address &&
        other.target == target &&
        other.text == text &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(address, target, text, start, end);
}
