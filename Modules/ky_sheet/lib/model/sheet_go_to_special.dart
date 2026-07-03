import 'cell/cell_address.dart';

enum SheetGoToSpecialKind {
  formulas,
  constants,
  blanks,
  formulaErrors,
  comments,
  hyperlinks,
  validations,
}

extension SheetGoToSpecialKindLabel on SheetGoToSpecialKind {
  String get label {
    return switch (this) {
      SheetGoToSpecialKind.formulas => 'Formulas',
      SheetGoToSpecialKind.constants => 'Constants',
      SheetGoToSpecialKind.blanks => 'Blanks',
      SheetGoToSpecialKind.formulaErrors => 'Formula Errors',
      SheetGoToSpecialKind.comments => 'Comments',
      SheetGoToSpecialKind.hyperlinks => 'Hyperlinks',
      SheetGoToSpecialKind.validations => 'Validations',
    };
  }
}

class SheetGoToSpecialResult {
  const SheetGoToSpecialResult({
    required this.kind,
    required this.usedRangeLabel,
    required this.totalCount,
    required this.matches,
  });

  final SheetGoToSpecialKind kind;
  final String usedRangeLabel;
  final int totalCount;
  final List<SheetGoToSpecialMatch> matches;

  bool get isTruncated => totalCount > matches.length;
}

class SheetGoToSpecialMatch {
  const SheetGoToSpecialMatch({
    required this.address,
    required this.title,
    required this.detail,
  });

  final CellAddress address;
  final String title;
  final String detail;

  String get label => address.label;
}
