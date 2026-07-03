// Minimal shim for excel library used in the codebase to satisfy compile-time references
// This is a compatibility shim while real Excel integration is disabled.

enum Underline { None, Single }

class Excel {
  Excel();
  factory Excel.decodeBytes(List<int> bytes) => Excel();
  static Excel createExcel() => Excel();

  // Simple tables map to emulate package:excel behaviour
  final Map<String, ExcelSheet> tables = {'Sheet1': ExcelSheet()};

  // Treat as sheet access by name
  ExcelSheet operator [](String name) => tables[name] ?? ExcelSheet();

  // Encode to bytes (not implemented - placeholder)
  List<int> encode() => <int>[];
}

class ExcelSheet {
  final String name;
  ExcelSheet([this.name = 'Sheet1']);

  /// Maximum rows/columns for compatibility with callers.
  int get maxRows => 1000;
  int get maxColumns => 1000;

  ExcelCell cell(dynamic index) => ExcelCell();
}

class ExcelCell extends Data {
  dynamic value;
  CellStyle? cellStyle;

  ExcelCell({this.value, this.cellStyle}) : super(style: cellStyle);
}

class CellIndex {
  static dynamic indexByColumnRow({required int columnIndex, required int rowIndex}) {
    return {'col': columnIndex, 'row': rowIndex};
  }
}

class TextCellValue {
  final String text;
  TextCellValue(this.text);
}

class CellStyle {
  bool isBold = false;
  bool isItalic = false;
  Underline underline = Underline.None;
  CellStyle({bool bold = false, bool italic = false, this.underline = Underline.None}) {
    isBold = bold;
    isItalic = italic;
  }
}

// Minimal Data class used by conversion helper
class Data {
  final CellStyle? cellStyle;
  Data({CellStyle? style}) : cellStyle = style;
}
