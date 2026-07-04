import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../widgets/editor/paragraph_widget.dart';

/// Widget to render a complete table in the document editor.
class TableWidget extends StatelessWidget {
  final TableModel table;
  final Function(int, int)? onCellTap;
  final bool isSelected;

  const TableWidget({
    Key? key,
    required this.table,
    this.onCellTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2.0),
              borderRadius: BorderRadius.circular(2.0),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.0),
        child: Table(
          columnWidths: _calculateColumnWidths(),
          border: _buildTableBorder(),
          children: _buildTableRows(),
        ),
      ),
    );
  }

  /// Calculates column widths based on content or equal distribution.
  Map<int, TableColumnWidth>? _calculateColumnWidths() {
    // For now, use equal width columns
    // Future enhancement: calculate based on content width
    return null;
  }

  /// Builds the table border based on model settings.
  TableBorder? _buildTableBorder() {
    final style = table.borderStyle;
    if (style == null) return null;

    return TableBorder(
      top: BorderSide(
        color: Color(style.top?.color ?? 0xFF000000),
        width: style.top?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.top?.style),
      ),
      bottom: BorderSide(
        color: Color(style.bottom?.color ?? 0xFF000000),
        width: style.bottom?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.bottom?.style),
      ),
      left: BorderSide(
        color: Color(style.left?.color ?? 0xFF000000),
        width: style.left?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.left?.style),
      ),
      right: BorderSide(
        color: Color(style.right?.color ?? 0xFF000000),
        width: style.right?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.right?.style),
      ),
      horizontalInside: BorderSide(
        color: Color(style.insideH?.color ?? 0xFF000000),
        width: style.insideH?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.insideH?.style),
      ),
      verticalInside: BorderSide(
        color: Color(style.insideV?.color ?? 0xFF000000),
        width: style.insideV?.width ?? 1.0,
        style: _borderStyleToBorderStyle(style.insideV?.style),
      ),
    );
  }

  BorderStyle _borderStyleToBorderStyle(String? style) {
    switch (style) {
      case 'dashed':
        return BorderStyle.solid; // Flutter doesn't support dashed directly in TableBorder
      case 'dotted':
        return BorderStyle.solid;
      default:
        return BorderStyle.solid;
    }
  }

  /// Builds the list of TableRow widgets.
  List<TableRow> _buildTableRows() {
    return table.rows.asMap().entries.map((entry) {
      final rowIndex = entry.key;
      final rowModel = entry.value;
      return TableRow(
        decoration: rowIndex % 2 == 1 && table.style == TableStyle.bandedRows
            ? BoxDecoration(color: Colors.grey[100])
            : null,
        children: rowModel.cells.asMap().entries.map((cellEntry) {
          final colIndex = cellEntry.key;
          final cellModel = cellEntry.value;
          
          // Skip rendering if this cell is merged into another
          if (cellModel.isMerged == true || cellModel.colSpan == 0) {
            return const SizedBox.shrink();
          }

          return TableCellWidget(
            cell: cellModel,
            onTap: onCellTap != null ? () => onCellTap!(rowIndex, colIndex) : null,
          );
        }).toList(),
      );
    }).toList();
  }
}

/// Widget to render an individual table cell.
class TableCellWidget extends StatelessWidget {
  final TableCell cell;
  final VoidCallback? onTap;

  const TableCellWidget({
    Key? key,
    required this.cell,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: cell.backgroundColor != null
              ? Color(cell.backgroundColor!)
              : null,
          border: _buildCellBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cell.content
              .map((paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ParagraphWidget(paragraph: paragraph),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Border? _buildCellBorder() {
    final style = cell.borderStyle;
    if (style == null) return null;

    return Border(
      top: BorderSide(
        color: Color(style.top?.color ?? 0x00000000),
        width: style.top?.width ?? 0.0,
      ),
      bottom: BorderSide(
        color: Color(style.bottom?.color ?? 0x00000000),
        width: style.bottom?.width ?? 0.0,
      ),
      left: BorderSide(
        color: Color(style.left?.color ?? 0x00000000),
        width: style.left?.width ?? 0.0,
      ),
      right: BorderSide(
        color: Color(style.right?.color ?? 0x00000000),
        width: style.right?.width ?? 0.0,
      ),
    );
  }
}
