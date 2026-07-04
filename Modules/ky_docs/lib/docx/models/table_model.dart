import 'paragraph_model.dart';
import 'style_model.dart';

/// Represents a single cell in a table
class TableCell {
  final List<Paragraph> content;
  final int colSpan;
  final int rowSpan;
  final CellBorderStyle? borderStyle;
  final String? backgroundColor;
  final double? width;
  final double? padding;

  TableCell({
    required this.content,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.borderStyle,
    this.backgroundColor,
    this.width,
    this.padding = 5.0,
  });

  TableCell copyWith({
    List<Paragraph>? content,
    int? colSpan,
    int? rowSpan,
    CellBorderStyle? borderStyle,
    String? backgroundColor,
    double? width,
    double? padding,
  }) {
    return TableCell(
      content: content ?? this.content,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      borderStyle: borderStyle ?? this.borderStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      width: width ?? this.width,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((p) => p.toJson()).toList(),
      'colSpan': colSpan,
      'rowSpan': rowSpan,
      'borderStyle': borderStyle?.toJson(),
      'backgroundColor': backgroundColor,
      'width': width,
      'padding': padding,
    };
  }

  factory TableCell.fromJson(Map<String, dynamic> json) {
    return TableCell(
      content: (json['content'] as List)
          .map((p) => Paragraph.fromJson(p))
          .toList(),
      colSpan: json['colSpan'] ?? 1,
      rowSpan: json['rowSpan'] ?? 1,
      borderStyle: json['borderStyle'] != null
          ? CellBorderStyle.fromJson(json['borderStyle'])
          : null,
      backgroundColor: json['backgroundColor'],
      width: json['width'],
      padding: json['padding'],
    );
  }
}

/// Represents a row in a table
class TableRow {
  final List<TableCell> cells;
  final double? height;
  final bool isHeaderRow;

  TableRow({
    required this.cells,
    this.height,
    this.isHeaderRow = false,
  });

  TableRow copyWith({
    List<TableCell>? cells,
    double? height,
    bool? isHeaderRow,
  }) {
    return TableRow(
      cells: cells ?? this.cells,
      height: height ?? this.height,
      isHeaderRow: isHeaderRow ?? this.isHeaderRow,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cells': cells.map((c) => c.toJson()).toList(),
      'height': height,
      'isHeaderRow': isHeaderRow,
    };
  }

  factory TableRow.fromJson(Map<String, dynamic> json) {
    return TableRow(
      cells: (json['cells'] as List)
          .map((c) => TableCell.fromJson(c))
          .toList(),
      height: json['height'],
      isHeaderRow: json['isHeaderRow'] ?? false,
    );
  }
}

/// Border style for table cells
enum BorderSideType { top, bottom, left, right, all, none }

enum BorderLineStyle { solid, dashed, dotted, double, none }

class CellBorderStyle {
  final BorderLineStyle style;
  final int size;
  final String color;

  const CellBorderStyle({
    this.style = BorderLineStyle.solid,
    this.size = 1,
    this.color = '#000000',
  });

  Map<String, dynamic> toJson() {
    return {
      'style': style.name,
      'size': size,
      'color': color,
    };
  }

  factory CellBorderStyle.fromJson(Map<String, dynamic> json) {
    return CellBorderStyle(
      style: BorderLineStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => BorderLineStyle.solid,
      ),
      size: json['size'] ?? 1,
      color: json['color'] ?? '#000000',
    );
  }
}

/// Main Table Model
class TableModel {
  final String id;
  final List<TableRow> rows;
  final CellBorderStyle? borderStyle;
  final TableAlignment alignment;
  final double? width; // Percentage or points
  final bool allowCellSpacing;
  final double? cellSpacing;

  TableModel({
    required this.id,
    required this.rows,
    this.borderStyle,
    this.alignment = TableAlignment.left,
    this.width,
    this.allowCellSpacing = false,
    this.cellSpacing,
  });

  int get rowCount => rows.length;
  int get columnCount {
    if (rows.isEmpty) return 0;
    return rows.first.cells.fold<int>(
      0,
      (sum, cell) => sum + cell.colSpan,
    );
  }

  TableModel copyWith({
    String? id,
    List<TableRow>? rows,
    CellBorderStyle? borderStyle,
    TableAlignment? alignment,
    double? width,
    bool? allowCellSpacing,
    double? cellSpacing,
  }) {
    return TableModel(
      id: id ?? this.id,
      rows: rows ?? this.rows,
      borderStyle: borderStyle ?? this.borderStyle,
      alignment: alignment ?? this.alignment,
      width: width ?? this.width,
      allowCellSpacing: allowCellSpacing ?? this.allowCellSpacing,
      cellSpacing: cellSpacing ?? this.cellSpacing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rows': rows.map((r) => r.toJson()).toList(),
      'borderStyle': borderStyle?.toJson(),
      'alignment': alignment.name,
      'width': width,
      'allowCellSpacing': allowCellSpacing,
      'cellSpacing': cellSpacing,
    };
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      rows: (json['rows'] as List)
          .map((r) => TableRow.fromJson(r))
          .toList(),
      borderStyle: json['borderStyle'] != null
          ? CellBorderStyle.fromJson(json['borderStyle'])
          : null,
      alignment: TableAlignment.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => TableAlignment.left,
      ),
      width: json['width'],
      allowCellSpacing: json['allowCellSpacing'] ?? false,
      cellSpacing: json['cellSpacing'],
    );
  }

  /// Helper to create a simple table with placeholder content
  factory TableModel.create({
    required int rows,
    required int cols,
    String? id,
  }) {
    final tableRows = List.generate(
      rows,
      (r) => TableRow(
        cells: List.generate(
          cols,
          (c) => TableCell(
            content: [
              Paragraph(
                id: 'cell-$r-$c',
                runs: [],
                styleId: 'Normal',
              )
            ],
          ),
        ),
        isHeaderRow: r == 0,
      ),
    );

    return TableModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      rows: tableRows,
      borderStyle: const CellBorderStyle(
        style: BorderLineStyle.solid,
        size: 1,
        color: '#000000',
      ),
    );
  }
}

enum TableAlignment { left, center, right }
