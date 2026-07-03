import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';

/// Visual table style families used by Ky Sheet structured tables.
enum SheetTableStyleId { prism, graphite, mint }

/// User-facing metadata for a Ky Sheet table style family.
extension SheetTableStyleIdLabel on SheetTableStyleId {
  /// Human-readable style name shown in table design controls.
  String get label {
    return switch (this) {
      SheetTableStyleId.prism => 'Prism',
      SheetTableStyleId.graphite => 'Graphite',
      SheetTableStyleId.mint => 'Mint',
    };
  }
}

/// Metadata for a structured table range in a worksheet.
class SheetTable {
  const SheetTable({
    required this.id,
    required this.name,
    required this.selection,
    this.styleId = SheetTableStyleId.prism,
    this.showHeaderRow = true,
    this.showBandedRows = true,
    this.showTotalsRow = false,
  });

  /// Stable table id used for persistence and future table operations.
  final String id;

  /// User-facing table name.
  final String name;

  /// Cell range covered by the table.
  final CellSelection selection;

  /// Distinct Ky Sheet visual style applied to the table.
  final SheetTableStyleId styleId;

  /// Whether the first row is treated as a table header.
  final bool showHeaderRow;

  /// Whether alternating body rows receive subtle visual banding.
  final bool showBandedRows;

  /// Whether the last row is treated as a table totals row.
  final bool showTotalsRow;

  int get minRow => selection.minRow;
  int get maxRow => selection.maxRow;
  int get minCol => selection.minCol;
  int get maxCol => selection.maxCol;

  /// Whether the current table range has a distinct totals row.
  bool get hasTotalsRow => showTotalsRow && (!showHeaderRow || maxRow > minRow);

  /// Creates a normalized table from an arbitrary selected range.
  factory SheetTable.fromSelection({
    required String id,
    required String name,
    required CellSelection selection,
    SheetTableStyleId styleId = SheetTableStyleId.prism,
  }) {
    return SheetTable(
      id: id,
      name: name,
      selection: CellSelection(
        CellAddress(selection.minRow, selection.minCol),
        CellAddress(selection.maxRow, selection.maxCol),
      ),
      styleId: styleId,
    );
  }

  /// Returns a copy with selectively updated table metadata.
  SheetTable copyWith({
    String? id,
    String? name,
    CellSelection? selection,
    SheetTableStyleId? styleId,
    bool? showHeaderRow,
    bool? showBandedRows,
    bool? showTotalsRow,
  }) {
    return SheetTable(
      id: id ?? this.id,
      name: name ?? this.name,
      selection: selection ?? this.selection,
      styleId: styleId ?? this.styleId,
      showHeaderRow: showHeaderRow ?? this.showHeaderRow,
      showBandedRows: showBandedRows ?? this.showBandedRows,
      showTotalsRow: showTotalsRow ?? this.showTotalsRow,
    );
  }

  /// Whether the table contains the provided cell address.
  bool contains(CellAddress address) => selection.contains(address);

  /// Whether the cell sits in this table's header row.
  bool isHeaderCell(CellAddress address) {
    return showHeaderRow && contains(address) && address.row == minRow;
  }

  /// Whether the cell sits in this table's totals row.
  bool isTotalsCell(CellAddress address) {
    return hasTotalsRow && contains(address) && address.row == maxRow;
  }

  /// Whether the cell should receive alternating body-row banding.
  bool isBandedBodyCell(CellAddress address) {
    if (!showBandedRows ||
        !contains(address) ||
        isHeaderCell(address) ||
        isTotalsCell(address)) {
      return false;
    }

    final firstBodyRow = showHeaderRow ? minRow + 1 : minRow;
    final lastBodyRow = hasTotalsRow ? maxRow - 1 : maxRow;
    if (address.row > lastBodyRow) return false;
    return (address.row - firstBodyRow).isOdd;
  }

  /// Serializes the table for workbook persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'selection': {
        'start': selection.start.toJson(),
        'end': (selection.end ?? selection.start).toJson(),
      },
      'styleId': styleId.name,
      'showHeaderRow': showHeaderRow,
      'showBandedRows': showBandedRows,
      'showTotalsRow': showTotalsRow,
    };
  }

  /// Restores table metadata from workbook persistence.
  factory SheetTable.fromJson(Map<String, dynamic> json) {
    final selectionJson = json['selection'];
    final selection = selectionJson is Map
        ? Map<String, dynamic>.from(selectionJson)
        : const <String, dynamic>{};
    final startJson = selection['start'];
    final endJson = selection['end'];
    final start = startJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(startJson))
        : CellAddress(0, 0);
    final end = endJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(endJson))
        : start;

    return SheetTable(
      id: json['id']?.toString() ?? 'table',
      name: json['name']?.toString() ?? 'Table',
      selection: CellSelection(start, end),
      styleId: SheetTableStyleId.values.firstWhere(
        (style) => style.name == json['styleId'],
        orElse: () => SheetTableStyleId.prism,
      ),
      showHeaderRow: json['showHeaderRow'] as bool? ?? true,
      showBandedRows: json['showBandedRows'] as bool? ?? true,
      showTotalsRow: json['showTotalsRow'] as bool? ?? false,
    );
  }
}
