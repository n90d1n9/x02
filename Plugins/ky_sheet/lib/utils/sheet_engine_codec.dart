import 'package:flutter/material.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_style.dart';
import '../model/workbook_sheet.dart';

class SheetEngineCodec {
  const SheetEngineCodec._();

  static const type = 'waraq_sheet_engine_workbook';
  static const engine = 'sheet_engine';

  static bool isSheetEngineJson(Map<String, dynamic> json) {
    if (json['type'] == type || json['engine'] == engine) return true;
    if (json['grids'] is List) return true;
    return json['name'] != null && json['cells'] is List;
  }

  static SheetWorkbook decodeWorkbook(Map<String, dynamic> json) {
    final sheetsJson = _sheetSnapshots(json);
    final sheets = [
      for (var index = 0; index < sheetsJson.length; index++)
        decodeSheet(sheetsJson[index], index: index),
    ];

    if (sheets.isEmpty) return SheetWorkbook.initial();

    final activeSheetId = _activeSheetId(json, sheets) ?? sheets.first.id;
    return SheetWorkbook(sheets: sheets, activeSheetId: activeSheetId);
  }

  static WorkbookSheet decodeSheet(Map<String, dynamic> json, {int index = 0}) {
    final name = json['name']?.toString().trim();
    final sheetName = name?.isNotEmpty == true ? name! : 'Sheet ${index + 1}';
    final id = json['id']?.toString().trim();
    return WorkbookSheet(
      id: id?.isNotEmpty == true ? id! : _sheetId(index, sheetName),
      name: sheetName,
      cells: _decodeCells(json['cells']),
    );
  }

  static Map<String, dynamic> encodeWorkbook(SheetWorkbook workbook) {
    return {
      'type': type,
      'engine': engine,
      'activeSheetId': workbook.activeSheetId,
      'sheets': [for (final sheet in workbook.sheets) encodeSheet(sheet)],
    };
  }

  static Map<String, dynamic> encodeSheet(WorkbookSheet sheet) {
    final cells =
        sheet.cells.entries
            .where((entry) => _hasCellContent(entry.value))
            .toList()
          ..sort((left, right) {
            final row = left.key.row.compareTo(right.key.row);
            return row == 0 ? left.key.col.compareTo(right.key.col) : row;
          });

    return {
      'id': sheet.id,
      'name': sheet.name,
      'max_col': _maxColumn(cells),
      'max_row': _maxRow(cells),
      'cells': [for (final entry in cells) _encodeCell(entry.key, entry.value)],
    };
  }

  static CellStyle decodeCellFormat(dynamic formatJson) {
    final format = _asMap(formatJson);
    if (format == null) return CellStyle();

    return CellStyle(
      bold: format['bold'] == true,
      italic: format['italic'] == true,
      backgroundColor: _decodeColor(format['background_color']),
      textColor: _decodeColor(format['text_color']) ?? Colors.black87,
      numberFormat: format['number_format']?.toString(),
    );
  }

  static Map<String, dynamic> encodeCellFormat(CellStyle style) {
    return {
      'bold': style.bold,
      'italic': style.italic,
      'background_color': _encodeColor(style.backgroundColor),
      'text_color': _encodeColor(style.textColor),
      'number_format': style.numberFormat,
    };
  }

  static List<Map<String, dynamic>> _sheetSnapshots(Map<String, dynamic> json) {
    final sheetsJson = json['sheets'] ?? json['grids'];
    if (sheetsJson is List) {
      return [
        for (final sheetJson in sheetsJson)
          if (sheetJson is Map) Map<String, dynamic>.from(sheetJson),
      ];
    }

    if (json.containsKey('cells') && json.containsKey('name')) {
      return [json];
    }

    return const [];
  }

  static String? _activeSheetId(
    Map<String, dynamic> json,
    List<WorkbookSheet> sheets,
  ) {
    final requestedId = json['activeSheetId']?.toString();
    if (requestedId != null && sheets.any((sheet) => sheet.id == requestedId)) {
      return requestedId;
    }

    final requestedName = json['activeSheetName']?.toString();
    if (requestedName != null) {
      for (final sheet in sheets) {
        if (sheet.name == requestedName) return sheet.id;
      }
    }

    final requestedIndex = (json['activeSheetIndex'] as num?)?.toInt();
    if (requestedIndex != null &&
        requestedIndex >= 0 &&
        requestedIndex < sheets.length) {
      return sheets[requestedIndex].id;
    }

    return null;
  }

  static Map<CellAddress, CellData> _decodeCells(dynamic cellsJson) {
    if (cellsJson is! List) return const {};

    final cells = <CellAddress, CellData>{};
    for (final entryJson in cellsJson) {
      if (entryJson is! Map) continue;
      final entry = Map<String, dynamic>.from(entryJson);
      final position = _asMap(entry['position']);
      final cell = _asMap(entry['cell']);
      if (position == null || cell == null) continue;

      final row = _asInt(position['row']);
      final col = _asInt(position['col']);
      if (row == null || col == null) continue;

      final rawContent = cell['raw_content']?.toString() ?? '';
      final evaluated = _decodeCellValue(cell['evaluated_value']);
      final formula = rawContent.trim().startsWith('=') ? rawContent : null;
      final value = formula == null
          ? (rawContent.isNotEmpty ? rawContent : evaluated.value)
          : evaluated.value;

      if (value.isEmpty && formula == null) continue;
      cells[CellAddress(row, col)] = CellData(
        value: value,
        formula: formula,
        style: decodeCellFormat(cell['format']),
      );
    }

    return cells;
  }

  static _DecodedEngineValue _decodeCellValue(dynamic valueJson) {
    if (valueJson == null || valueJson == 'Empty') {
      return const _DecodedEngineValue('');
    }

    if (valueJson is String || valueJson is num || valueJson is bool) {
      return _DecodedEngineValue(valueJson.toString());
    }

    final value = _asMap(valueJson);
    if (value == null || value.isEmpty) return const _DecodedEngineValue('');

    if (value.containsKey('Number')) {
      return _DecodedEngineValue(_formatNumber(value['Number']));
    }
    if (value.containsKey('String')) {
      return _DecodedEngineValue(value['String']?.toString() ?? '');
    }
    if (value.containsKey('Boolean')) {
      return _DecodedEngineValue(value['Boolean'] == true ? 'TRUE' : 'FALSE');
    }
    if (value.containsKey('Error')) {
      return _DecodedEngineValue(value['Error']?.toString() ?? '');
    }

    return const _DecodedEngineValue('');
  }

  static Map<String, dynamic> _encodeCell(CellAddress address, CellData cell) {
    return {
      'position': {'col': address.col, 'row': address.row},
      'cell': {
        'raw_content': cell.formula ?? cell.value,
        'evaluated_value': _encodeCellValue(cell.value),
        'format': encodeCellFormat(cell.style),
      },
    };
  }

  static Object _encodeCellValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Empty';
    if (trimmed.startsWith('#')) return {'Error': trimmed};
    if (trimmed.toLowerCase() == 'true') return {'Boolean': true};
    if (trimmed.toLowerCase() == 'false') return {'Boolean': false};

    final number = num.tryParse(trimmed);
    if (number != null && _isPlainNumber(trimmed)) {
      return {'Number': number.toDouble()};
    }

    return {'String': value};
  }

  static bool _hasCellContent(CellData cell) {
    return cell.value.isNotEmpty || cell.formula?.isNotEmpty == true;
  }

  static int _maxColumn(List<MapEntry<CellAddress, CellData>> cells) {
    var max = 0;
    for (final cell in cells) {
      if (cell.key.col > max) max = cell.key.col;
    }
    return max;
  }

  static int _maxRow(List<MapEntry<CellAddress, CellData>> cells) {
    var max = 0;
    for (final cell in cells) {
      if (cell.key.row > max) max = cell.key.row;
    }
    return max;
  }

  static String _sheetId(int index, String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'sheet-engine-${index + 1}-${slug.isEmpty ? 'sheet' : slug}';
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _formatNumber(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (number == null) return '';
    if (number % 1 == 0) return number.toInt().toString();
    return number.toString();
  }

  static bool _isPlainNumber(String value) {
    return RegExp(r'^-?(0|[1-9]\d*)(\.\d+)?$').hasMatch(value);
  }

  static Color? _decodeColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return Color(value);

    var hex = value.toString().trim();
    if (hex.isEmpty) return null;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  static String? _encodeColor(Color? color) {
    if (color == null) return null;
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}

class _DecodedEngineValue {
  const _DecodedEngineValue(this.value);

  final String value;
}
