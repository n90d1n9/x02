import 'package:flutter/material.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/column_config.dart';
import '../model/conditional_format_rule.dart';
import '../model/row_config.dart';
import '../model/sheet_filter_rule.dart';
import '../model/sheet_named_range.dart';
import '../model/sheet_table.dart';
import '../model/workbook_sheet.dart';

class SheetWorkbookCodec {
  const SheetWorkbookCodec._();

  static const type = 'ky_sheet_workbook';
  static const version = '4.4';

  static Map<String, dynamic> encode(SheetWorkbook workbook) {
    return {
      'type': type,
      'version': version,
      'activeSheetId': workbook.activeSheetId,
      'sheets': [for (final sheet in workbook.sheets) _encodeSheet(sheet)],
    };
  }

  static SheetWorkbook decode(Map<String, dynamic> json) {
    final sheetsJson = json['sheets'];
    if (sheetsJson is! List) {
      return _decodeLegacySingleSheet(json);
    }

    final sheets = [
      for (final sheetJson in sheetsJson)
        if (sheetJson is Map)
          _decodeSheet(Map<String, dynamic>.from(sheetJson)),
    ];

    if (sheets.isEmpty) return SheetWorkbook.initial();

    final requestedActiveId = json['activeSheetId']?.toString();
    final activeSheetId =
        sheets.any((sheet) => sheet.id == requestedActiveId && !sheet.hidden)
        ? requestedActiveId!
        : sheets
              .firstWhere((sheet) => !sheet.hidden, orElse: () => sheets.first)
              .id;

    return SheetWorkbook(sheets: sheets, activeSheetId: activeSheetId);
  }

  static Map<String, dynamic> _encodeSheet(WorkbookSheet sheet) {
    return {
      'id': sheet.id,
      'name': sheet.name,
      if (sheet.tabColor != null) 'tabColor': _encodeColor(sheet.tabColor),
      if (sheet.hidden) 'hidden': true,
      'cells': _encodeCells(sheet.cells),
      'metadata': _encodeMetadata(sheet.metadata),
    };
  }

  static WorkbookSheet _decodeSheet(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim();
    return WorkbookSheet(
      id: json['id']?.toString() ?? _fallbackSheetId(json['name']),
      name: name?.isNotEmpty ?? false ? name! : 'Sheet',
      tabColor: _decodeColor(json['tabColor']),
      hidden: json['hidden'] == true,
      cells: _decodeCells(json['cells']),
      metadata: _decodeMetadata(json['metadata']),
    );
  }

  static SheetWorkbook _decodeLegacySingleSheet(Map<String, dynamic> json) {
    const sheetId = 'sheet-1';
    final sheet = WorkbookSheet(
      id: sheetId,
      name: 'Sheet1',
      cells: _decodeCells(json['cells']),
      metadata: _decodeMetadata(json['metadata']),
    );

    return SheetWorkbook(sheets: [sheet], activeSheetId: sheetId);
  }

  static Map<String, dynamic> _encodeCells(Map<CellAddress, CellData> cells) {
    return {
      for (final entry in cells.entries)
        '${entry.key.row},${entry.key.col}': entry.value.toJson(),
    };
  }

  static Map<CellAddress, CellData> _decodeCells(dynamic cellsJson) {
    if (cellsJson is! Map) return {};

    final cells = <CellAddress, CellData>{};
    for (final entry in cellsJson.entries) {
      final key = entry.key.toString();
      final parts = key.split(',');
      if (parts.length != 2 || entry.value is! Map) continue;

      final row = int.tryParse(parts[0]);
      final col = int.tryParse(parts[1]);
      if (row == null || col == null) continue;

      cells[CellAddress(row, col)] = CellData.fromJson(
        Map<String, dynamic>.from(entry.value),
      );
    }
    return cells;
  }

  static Map<String, dynamic> _encodeMetadata(SheetMetadata metadata) {
    final sortMetadata = <String, dynamic>{'ascending': metadata.sortAscending};
    if (metadata.sortColumn != null) {
      sortMetadata['column'] = metadata.sortColumn;
    }

    return {
      'conditionalFormatRules': [
        for (final rule in metadata.conditionalFormatRules) rule.toJson(),
      ],
      'namedRanges': [for (final range in metadata.namedRanges) range.toJson()],
      'rowConfig': {
        for (final entry in metadata.rowConfig.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'columnConfig': {
        for (final entry in metadata.columnConfig.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'filters': {
        for (final entry in metadata.filters.entries)
          entry.key.toString(): entry.value,
      },
      'filterRules': {
        for (final entry in metadata.filterRules.entries)
          if (entry.value.isActive) entry.key.toString(): entry.value.toJson(),
      },
      'tables': [for (final table in metadata.tables) table.toJson()],
      'sort': sortMetadata,
      if (metadata.freezePane != null)
        'freezePane': metadata.freezePane!.toJson(),
      'zoom': metadata.zoom,
    };
  }

  static SheetMetadata _decodeMetadata(dynamic metadataJson) {
    if (metadataJson is! Map) return const SheetMetadata();

    final metadata = Map<String, dynamic>.from(metadataJson);
    final sortJson = metadata['sort'];
    final sort = sortJson is Map ? Map<String, dynamic>.from(sortJson) : null;

    final filters = _decodeFilters(metadata['filters']);
    final filterRules = _decodeFilterRules(metadata['filterRules'], filters);

    return SheetMetadata(
      conditionalFormatRules: _decodeConditionalRules(
        metadata['conditionalFormatRules'],
      ),
      namedRanges: _decodeNamedRanges(metadata['namedRanges']),
      rowConfig: _decodeRowConfig(metadata['rowConfig']),
      columnConfig: _decodeColumnConfig(metadata['columnConfig']),
      filters: filters,
      filterRules: filterRules,
      tables: _decodeTables(metadata['tables']),
      sortColumn: (sort?['column'] as num?)?.toInt(),
      sortAscending: sort?['ascending'] as bool? ?? true,
      freezePane: _decodeFreezePane(metadata['freezePane']),
      zoom: (metadata['zoom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static List<ConditionalFormatRule> _decodeConditionalRules(dynamic json) {
    if (json is! List) return const [];

    return [
      for (final ruleJson in json)
        if (ruleJson is Map)
          ConditionalFormatRule.fromJson(Map<String, dynamic>.from(ruleJson)),
    ];
  }

  static List<SheetNamedRange> _decodeNamedRanges(dynamic json) {
    if (json is! List) return const [];

    return [
      for (final rangeJson in json)
        if (rangeJson is Map)
          SheetNamedRange.fromJson(Map<String, dynamic>.from(rangeJson)),
    ];
  }

  static Map<int, RowConfig> _decodeRowConfig(dynamic json) {
    if (json is! Map) return const {};

    return {
      for (final entry in json.entries)
        if (int.tryParse(entry.key.toString()) != null && entry.value is Map)
          int.parse(entry.key.toString()): RowConfig.fromJson(
            Map<String, dynamic>.from(entry.value),
          ),
    };
  }

  static Map<int, ColumnConfig> _decodeColumnConfig(dynamic json) {
    if (json is! Map) return const {};

    return {
      for (final entry in json.entries)
        if (int.tryParse(entry.key.toString()) != null && entry.value is Map)
          int.parse(entry.key.toString()): ColumnConfig.fromJson(
            Map<String, dynamic>.from(entry.value),
          ),
    };
  }

  static Map<int, String> _decodeFilters(dynamic json) {
    if (json is! Map) return const {};

    return {
      for (final entry in json.entries)
        if (int.tryParse(entry.key.toString()) != null)
          int.parse(entry.key.toString()): entry.value.toString(),
    };
  }

  static Map<int, SheetFilterRule> _decodeFilterRules(
    dynamic json,
    Map<int, String> legacyFilters,
  ) {
    if (json is Map) {
      return {
        for (final entry in json.entries)
          if (int.tryParse(entry.key.toString()) != null && entry.value is Map)
            int.parse(entry.key.toString()): SheetFilterRule.fromJson(
              Map<String, dynamic>.from(entry.value),
            ),
      };
    }

    return {
      for (final entry in legacyFilters.entries)
        if (entry.value.trim().isNotEmpty)
          entry.key: SheetFilterRule.contains(entry.value),
    };
  }

  static List<SheetTable> _decodeTables(dynamic json) {
    if (json is! List) return const [];

    return [
      for (final tableJson in json)
        if (tableJson is Map)
          SheetTable.fromJson(Map<String, dynamic>.from(tableJson)),
    ];
  }

  static CellAddress? _decodeFreezePane(dynamic json) {
    if (json is! Map) return null;
    return CellAddress.fromJson(Map<String, dynamic>.from(json));
  }

  static int? _encodeColor(Color? color) => color?.toARGB32();

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

  static String _fallbackSheetId(dynamic name) {
    final normalized = name?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'sheet';
    return 'sheet-${normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
  }
}
