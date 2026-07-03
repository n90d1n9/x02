import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_style.dart';
import 'sheet_engine_codec.dart';
import 'sheet_engine_edit_codec.dart';

class SheetEngineOperationDiff {
  const SheetEngineOperationDiff._();

  static List<Map<String, dynamic>> buildEdits({
    required Map<CellAddress, CellData> before,
    required Map<CellAddress, CellData> after,
  }) {
    final addresses = {...before.keys, ...after.keys}.toList()
      ..sort(_compareAddresses);
    final edits = <Map<String, dynamic>>[];

    for (final address in addresses) {
      final beforeCell = before[address];
      final afterCell = after[address];
      if (beforeCell == null && afterCell == null) continue;

      if (afterCell == null) {
        edits.add(SheetEngineEditCodec.clearCell(address));
        continue;
      }

      final beforeRaw = beforeCell == null
          ? null
          : SheetEngineEditCodec.rawContent(beforeCell);
      final afterRaw = SheetEngineEditCodec.rawContent(afterCell);
      final rawChanged = beforeRaw != afterRaw;
      final formatChanged = beforeCell == null
          ? !_isDefaultEngineFormat(afterCell.style)
          : !_sameEngineFormat(beforeCell.style, afterCell.style);

      if (afterRaw.isEmpty && _isDefaultEngineFormat(afterCell.style)) {
        if (beforeCell != null) {
          edits.add(SheetEngineEditCodec.clearCell(address));
        }
        continue;
      }

      if (rawChanged && afterRaw.isNotEmpty) {
        edits.add(SheetEngineEditCodec.setCellRaw(address, afterRaw));
      }

      if (formatChanged) {
        edits.add(SheetEngineEditCodec.setCellFormat(address, afterCell.style));
      }
    }

    return edits;
  }

  static int _compareAddresses(CellAddress left, CellAddress right) {
    final row = left.row.compareTo(right.row);
    return row == 0 ? left.col.compareTo(right.col) : row;
  }

  static bool _sameEngineFormat(CellStyle left, CellStyle right) {
    return _formatSignature(left) == _formatSignature(right);
  }

  static bool _isDefaultEngineFormat(CellStyle style) {
    return _sameEngineFormat(style, CellStyle());
  }

  static String _formatSignature(CellStyle style) {
    return SheetEngineCodec.encodeCellFormat(style).toString();
  }
}
