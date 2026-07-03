import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';

class SheetClipboardCodec {
  const SheetClipboardCodec._();

  static String encodeSelection(
    CellSelection selection,
    Map<CellAddress, CellData> cells,
  ) {
    final rows = <List<String>>[];

    for (var row = selection.minRow; row <= selection.maxRow; row++) {
      final fields = <String>[];
      for (var col = selection.minCol; col <= selection.maxCol; col++) {
        final cell = cells[CellAddress(row, col)];
        fields.add(cell?.formula ?? cell?.value ?? '');
      }
      rows.add(fields);
    }

    return encodeRows(rows);
  }

  static String encodeRows(List<List<String>> rows) {
    return rows.map((row) => row.map(_encodeField).join('\t')).join('\n');
  }

  static List<List<String>> decodeRows(String text) {
    if (text.isEmpty) return [];

    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var endedWithRowBreak = false;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];

      if (inQuotes) {
        if (char == '"') {
          final hasEscapedQuote =
              index + 1 < text.length && text[index + 1] == '"';
          if (hasEscapedQuote) {
            field.write('"');
            index++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
        endedWithRowBreak = false;
        continue;
      }

      if (char == '"') {
        inQuotes = true;
        endedWithRowBreak = false;
      } else if (char == '\t') {
        row.add(field.toString());
        field.clear();
        endedWithRowBreak = false;
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' &&
            index + 1 < text.length &&
            text[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field.clear();
        endedWithRowBreak = true;
      } else {
        field.write(char);
        endedWithRowBreak = false;
      }
    }

    if (!endedWithRowBreak || row.isNotEmpty || field.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows;
  }

  static String _encodeField(String value) {
    final needsQuotes =
        value.contains('\t') ||
        value.contains('\n') ||
        value.contains('\r') ||
        value.contains('"');
    if (!needsQuotes) return value;

    return '"${value.replaceAll('"', '""')}"';
  }
}
