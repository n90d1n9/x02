import 'package:flutter/material.dart';
import '../../models/table_model.dart';
import '../../services/table_service.dart';

/// Toolbar widget for table operations (insert, design, layout).
class TableToolbar extends StatefulWidget {
  final TableModel? selectedTable;
  final Function(TableModel)? onTableInserted;
  final Function(int, int, int, int)? onMergeCells;
  final Function(int, int)? onSplitCell;

  const TableToolbar({
    Key? key,
    this.selectedTable,
    this.onTableInserted,
    this.onMergeCells,
    this.onSplitCell,
  }) : super(key: key);

  @override
  State<TableToolbar> createState() => _TableToolbarState();
}

class _TableToolbarState extends State<TableToolbar> {
  final _tableService = TableService();
  bool _isGridOpen = false;
  int _hoverRows = 0;
  int _hoverCols = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Insert Table Section
        if (widget.selectedTable == null) ...[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.table_chart),
                tooltip: 'Insert Table',
                onPressed: () => setState(() => _isGridOpen = !_isGridOpen),
              ),
              if (_isGridOpen) _buildGridSelector(),
            ],
          ),
        ],

        // Table Design & Layout Tools (when table is selected)
        if (widget.selectedTable != null) ...[
          _buildDesignTools(),
          const Divider(height: 16),
          _buildLayoutTools(),
        ],
      ],
    );
  }

  /// Builds the grid selector popup for inserting tables.
  Widget _buildGridSelector() {
    return Positioned(
      top: 40,
      left: 0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 2.0,
                crossAxisSpacing: 2.0,
              ),
              itemCount: 100, // 10x10 grid
              itemBuilder: (context, index) {
                final row = index ~/ 10 + 1;
                final col = index % 10 + 1;
                final isSelected = row <= _hoverRows && col <= _hoverCols;

                return GestureDetector(
                  onEnter: (_) {
                    setState(() {
                      _hoverRows = row;
                      _hoverCols = col;
                    });
                  },
                  onTap: () {
                    _insertTable(_hoverRows, _hoverCols);
                    setState(() => _isGridOpen = false);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8.0),
            Text(
              '${_hoverRows}x${_hoverCols} Table',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  void _insertTable(int rows, int cols) {
    final table = _tableService.createTable(rows, cols);
    widget.onTableInserted?.call(table);
  }

  /// Builds the Design tab tools.
  Widget _buildDesignTools() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildDropdownButton<String>(
          icon: Icons.border_all,
          tooltip: 'Borders',
          items: ['All Borders', 'Outside Borders', 'Inside Borders', 'No Border'],
          onChanged: (value) {
            // Apply border style logic here
          },
        ),
        _buildColorPickerButton(
          icon: Icons.format_color_fill,
          tooltip: 'Shading',
          onColorSelected: (color) {
            // Apply shading logic here
          },
        ),
        _buildDropdownButton<String>(
          icon: Icons.style,
          tooltip: 'Table Styles',
          items: ['Grid Table', 'Banded Rows', 'Banded Columns', 'Plain'],
          onChanged: (value) {
            // Apply table style
          },
        ),
      ],
    );
  }

  /// Builds the Layout tab tools.
  Widget _buildLayoutTools() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildActionButton(
          icon: Icons.add_row_above,
          tooltip: 'Insert Row Above',
          onPressed: () {
            // Logic to insert row above
          },
        ),
        _buildActionButton(
          icon: Icons.add_row_below,
          tooltip: 'Insert Row Below',
          onPressed: () {
            // Logic to insert row below
          },
        ),
        _buildActionButton(
          icon: Icons.add_column_left,
          tooltip: 'Insert Column Left',
          onPressed: () {
            // Logic to insert column left
          },
        ),
        _buildActionButton(
          icon: Icons.add_column_right,
          tooltip: 'Insert Column Right',
          onPressed: () {
            // Logic to insert column right
          },
        ),
        const VerticalDivider(width: 16.0),
        _buildActionButton(
          icon: Icons.merge_cells,
          tooltip: 'Merge Cells',
          onPressed: () {
            // Logic to merge selected cells
          },
        ),
        _buildActionButton(
          icon: Icons.split_cells,
          tooltip: 'Split Cell',
          onPressed: () {
            // Logic to split cell
          },
        ),
        _buildActionButton(
          icon: Icons.delete,
          tooltip: 'Delete Table',
          color: Colors.red,
          onPressed: () {
            // Logic to delete table
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildDropdownButton<T>({
    required IconData icon,
    required String tooltip,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildColorPickerButton({
    required IconData icon,
    required String tooltip,
    required Function(int) onColorSelected,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        // Show color picker dialog
      },
    );
  }
}
