import 'dart:math';
import '../models/table_model.dart';
import '../models/document_state.dart';
import '../models/paragraph_model.dart';
import '../models/run_model.dart';

/// Service class for handling all table-related operations in the document.
class TableService {
  /// Creates a new table with the specified number of rows and columns.
  /// Each cell is initialized with an empty paragraph.
  TableModel createTable(int rows, int cols, {double widthPercent = 100.0}) {
    if (rows < 1 || cols < 1) {
      throw ArgumentError('Rows and columns must be at least 1');
    }

    final tableRows = <TableRow>[];
    for (var i = 0; i < rows; i++) {
      final cells = <TableCell>[];
      for (var j = 0; j < cols; j++) {
        cells.add(TableCell(
          content: [
            Paragraph(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i_$j',
              runs: [
                Run(text: '', styles: TextStyleModel()),
              ],
            ),
          ],
          colSpan: 1,
          rowSpan: 1,
          backgroundColor: null,
          borderStyle: null,
        ));
      }
      tableRows.add(TableRow(cells: cells));
    }

    return TableModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rows: tableRows,
      widthPercent: widthPercent,
      alignment: TableAlignment.left,
      borderStyle: TableBorderStyle(
        top: BorderLine(width: 1.0, color: 0xFF000000),
        bottom: BorderLine(width: 1.0, color: 0xFF000000),
        left: BorderLine(width: 1.0, color: 0xFF000000),
        right: BorderLine(width: 1.0, color: 0xFF000000),
        insideH: BorderLine(width: 1.0, color: 0xFF000000),
        insideV: BorderLine(width: 1.0, color: 0xFF000000),
      ),
    );
  }

  /// Inserts a new row into the table at the specified index.
  /// [position] can be 'above' or 'below' the target row.
  void insertRow(TableModel table, int rowIndex, {String position = 'below'}) {
    if (rowIndex < 0 || rowIndex >= table.rows.length) {
      throw ArgumentError('Invalid row index');
    }

    final colCount = table.rows.first.cells.length;
    final newCells = <TableCell>[];
    
    for (var i = 0; i < colCount; i++) {
      newCells.add(TableCell(
        content: [
          Paragraph(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_new',
            runs: [Run(text: '', styles: TextStyleModel())],
          ),
        ],
        colSpan: 1,
        rowSpan: 1,
      ));
    }

    final newRow = TableRow(cells: newCells);
    
    if (position == 'above') {
      table.rows.insert(rowIndex, newRow);
    } else {
      table.rows.insert(rowIndex + 1, newRow);
    }
  }

  /// Deletes a row from the table at the specified index.
  void deleteRow(TableModel table, int rowIndex) {
    if (rowIndex < 0 || rowIndex >= table.rows.length) {
      throw ArgumentError('Invalid row index');
    }
    if (table.rows.length <= 1) {
      throw StateError('Cannot delete the last remaining row');
    }
    table.rows.removeAt(rowIndex);
  }

  /// Inserts a new column into the table at the specified index.
  void insertColumn(TableModel table, int colIndex, {String position = 'right'}) {
    if (colIndex < 0 || colIndex >= table.rows.first.cells.length) {
      throw ArgumentError('Invalid column index');
    }

    for (var row in table.rows) {
      // Handle rowspan: if a cell spans multiple rows, we only add to the first row of the span
      // For simplicity in this basic implementation, we assume no complex rowspan crossing insertion point
      // A robust implementation would need to adjust colSpans
      
      int effectiveIndex = colIndex;
      // Adjust index if we are inside a colspan cell
      int currentCol = 0;
      for (var i = 0; i < row.cells.length; i++) {
        if (currentCol > effectiveIndex) {
          effectiveIndex = i;
          break;
        }
        currentCol += row.cells[i].colSpan;
      }

      final newCell = TableCell(
        content: [
          Paragraph(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_col',
            runs: [Run(text: '', styles: TextStyleModel())],
          ),
        ],
        colSpan: 1,
        rowSpan: 1,
      );

      if (position == 'left') {
        row.cells.insert(effectiveIndex, newCell);
      } else {
        // Insert after the cell at effectiveIndex
        row.cells.insert(effectiveIndex + 1, newCell);
      }
    }
  }

  /// Deletes a column from the table at the specified index.
  void deleteColumn(TableModel table, int colIndex) {
    if (colIndex < 0 || colIndex >= table.rows.first.cells.length) {
      throw ArgumentError('Invalid column index');
    }
    if (table.rows.first.cells.length <= 1) {
      throw StateError('Cannot delete the last remaining column');
    }

    for (var row in table.rows) {
      // Simplified: assumes uniform grid. Real implementation needs colspan logic
      if (colIndex < row.cells.length) {
        row.cells.removeAt(colIndex);
      }
    }
  }

  /// Merges a range of cells into a single cell.
  void mergeCells(
    TableModel table,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    if (startRow > endRow || startCol > endCol) {
      throw ArgumentError('Start coordinates must be less than or equal to end coordinates');
    }
    if (endRow >= table.rows.length || endCol >= table.rows.first.cells.length) {
      throw ArgumentError('End coordinates out of bounds');
    }

    final startCell = table.rows[startRow].cells[startCol];
    
    // Calculate new spans
    final newRowSpan = endRow - startRow + 1;
    final newColSpan = endCol - startCol + 1;

    // Update the top-left cell
    table.rows[startRow].cells[startCol] = TableCell(
      content: startCell.content, // Keep content of the first cell
      colSpan: newColSpan,
      rowSpan: newRowSpan,
      backgroundColor: startCell.backgroundColor,
      borderStyle: startCell.borderStyle,
    );

    // Remove or mark other cells in the range as merged
    for (var r = startRow; r <= endRow; r++) {
      for (var c = startCol; c <= endCol; c++) {
        if (r == startRow && c == startCol) continue;
        
        // In a real implementation, we might replace these with a "MergedCell" reference
        // or remove them and adjust the grid logic in the renderer.
        // Here we set them to a placeholder that the renderer skips.
        table.rows[r].cells[c] = TableCell(
          content: [],
          colSpan: 0, // Mark as merged/skipped
          rowSpan: 0,
          isMerged: true,
        );
      }
    }
  }

  /// Splits a previously merged cell back into individual cells.
  void splitCell(TableModel table, int row, int col) {
    if (row >= table.rows.length || col >= table.rows[row].cells.length) {
      throw ArgumentError('Invalid cell coordinates');
    }

    final cell = table.rows[row].cells[col];
    if (!cell.isMerged && cell.colSpan == 1 && cell.rowSpan == 1) {
      return; // Nothing to split
    }

    final originalRowSpan = cell.rowSpan > 0 ? cell.rowSpan : 1;
    final originalColSpan = cell.colSpan > 0 ? cell.colSpan : 1;

    // Restore the main cell
    table.rows[row].cells[col] = TableCell(
      content: cell.content,
      colSpan: 1,
      rowSpan: 1,
      isMerged: false,
      backgroundColor: cell.backgroundColor,
      borderStyle: cell.borderStyle,
    );

    // Create new cells for the span area
    for (var r = row; r < row + originalRowSpan; r++) {
      for (var c = col; c < col + originalColSpan; c++) {
        if (r == row && c == col) continue;
        
        // Ensure the row exists and has enough columns (simplified)
        if (r < table.rows.length) {
           // If we are re-filling gaps, we insert or replace
           // This logic depends heavily on how the "merged" state was stored.
           // Assuming we replaced them with isMerged=true placeholders:
           if (c < table.rows[r].cells.length) {
             table.rows[r].cells[c] = TableCell(
               content: [Paragraph(id: 'split', runs: [Run(text: '')])],
               colSpan: 1,
               rowSpan: 1,
               isMerged: false,
             );
           }
        }
      }
    }
  }

  /// Updates the style (background, borders) of a specific cell.
  void updateCellStyle(
    TableModel table,
    int row,
    int col,
    int? backgroundColor,
    TableBorderStyle? borderStyle,
  ) {
    if (row >= table.rows.length || col >= table.rows[row].cells.length) {
      throw ArgumentError('Invalid cell coordinates');
    }

    final oldCell = table.rows[row].cells[col];
    table.rows[row].cells[col] = TableCell(
      content: oldCell.content,
      colSpan: oldCell.colSpan,
      rowSpan: oldCell.rowSpan,
      isMerged: oldCell.isMerged,
      backgroundColor: backgroundColor ?? oldCell.backgroundColor,
      borderStyle: borderStyle ?? oldCell.borderStyle,
    );
  }
}
