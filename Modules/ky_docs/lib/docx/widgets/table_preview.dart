import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_table.dart';
import '../states/provider.dart';

class DocxTablePreview extends ConsumerWidget {
  final DocumentTable table;

  const DocxTablePreview({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Table ${table.rows}x${table.columns}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => _showAddMenu(context, ref),
                  tooltip: 'Add Row/Column',
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DocxTableEditorDialog(table: table),
                    );
                  },
                  tooltip: 'Full Editor',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    ref.read(documentProvider.notifier).deleteTable(table.id);
                  },
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: table.data.asMap().entries.map((rowEntry) {
                  final rowIndex = rowEntry.key;
                  final row = rowEntry.value;
                  return TableRow(
                    decoration: rowIndex == 0 && table.hasHeader
                        ? BoxDecoration(color: Colors.blue.shade50)
                        : null,
                    children: row.asMap().entries.map((cellEntry) {
                      final colIndex = cellEntry.key;
                      final cell = cellEntry.value;
                      return TableCell(
                        child: InkWell(
                          onTap: () => _showEditTableCellDialog(
                            context,
                            ref,
                            table,
                            rowIndex,
                            colIndex,
                            cell,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 60,
                              minHeight: 30,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              cell.isEmpty ? '(tap to edit)' : cell,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: rowIndex == 0 && table.hasHeader
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: cell.isEmpty ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: const [
        PopupMenuItem(
          value: 'row',
          child: Row(
            children: [
              Icon(Icons.table_rows, size: 18),
              SizedBox(width: 8),
              Text('Add Row'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'column',
          child: Row(
            children: [
              Icon(Icons.view_column, size: 18),
              SizedBox(width: 8),
              Text('Add Column'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'row') {
        ref.read(documentProvider.notifier).addTableRow(table.id);
      } else if (value == 'column') {
        ref.read(documentProvider.notifier).addTableColumn(table.id);
      }
    });
  }
}

class DocxTableEditorDialog extends ConsumerWidget {
  final DocumentTable table;

  const DocxTableEditorDialog({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentProvider);
    final currentTable = docState.tables.firstWhere(
      (candidate) => candidate.id == table.id,
      orElse: () => table,
    );

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Table Editor - ${currentTable.rows}x${currentTable.columns}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(documentProvider.notifier).addTableRow(table.id);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(documentProvider.notifier)
                        .addTableColumn(table.id);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Column'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    defaultColumnWidth: const FixedColumnWidth(120),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: [
                          const TableCell(
                            child: SizedBox(width: 30, height: 30),
                          ),
                          ...List.generate(currentTable.columns, (colIndex) {
                            return TableCell(
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () {
                                    ref
                                        .read(documentProvider.notifier)
                                        .deleteTableColumn(table.id, colIndex);
                                  },
                                  tooltip: 'Delete Column',
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      ...currentTable.data.asMap().entries.map((rowEntry) {
                        final rowIndex = rowEntry.key;
                        final row = rowEntry.value;
                        return TableRow(
                          decoration: rowIndex == 0 && currentTable.hasHeader
                              ? BoxDecoration(color: Colors.blue.shade50)
                              : null,
                          children: [
                            TableCell(
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () {
                                    ref
                                        .read(documentProvider.notifier)
                                        .deleteTableRow(table.id, rowIndex);
                                  },
                                  tooltip: 'Delete Row',
                                ),
                              ),
                            ),
                            ...row.asMap().entries.map((cellEntry) {
                              final colIndex = cellEntry.key;
                              final cell = cellEntry.value;
                              return TableCell(
                                child: InkWell(
                                  onTap: () => _showEditTableCellDialog(
                                    context,
                                    ref,
                                    currentTable,
                                    rowIndex,
                                    colIndex,
                                    cell,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      cell.isEmpty ? '(tap to edit)' : cell,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            rowIndex == 0 &&
                                                currentTable.hasHeader
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: cell.isEmpty
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showEditTableCellDialog(
  BuildContext context,
  WidgetRef ref,
  DocumentTable table,
  int row,
  int column,
  String currentValue,
) {
  final controller = TextEditingController(text: currentValue);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Cell (${row + 1}, ${column + 1})'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter text',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(documentProvider.notifier)
                .updateTableCell(table.id, row, column, controller.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
