import 'package:flutter/material.dart';

import '../model/sheet_pivot_table.dart';
import '../service/pivot_table_manager.dart';
import '../state/toolbar_provider.dart';

/// Dialog for creating and configuring pivot tables.
class PivotTableDialog extends StatefulWidget {
  const PivotTableDialog({
    super.key,
    required this.controller,
    required this.sourceSelection,
    this.existingPivotTable,
  });

  final ToolbarController controller;
  final CellSelection sourceSelection;
  final SheetPivotTable? existingPivotTable;

  @override
  State<PivotTableDialog> createState() => _PivotTableDialogState();
}

class _PivotTableDialogState extends State<PivotTableDialog> {
  late PivotTableManager _manager;
  late SheetPivotTable _pivotTable;
  late TextEditingController _nameController;
  late List<String> _availableColumns;

  // Drag and drop state
  PivotArea? _draggedFieldArea;
  int? _draggedFieldIndex;

  @override
  void initState() {
    super.initState();
    _manager = PivotTableManager(widget.controller);
    _nameController = TextEditingController(
      text: widget.existingPivotTable?.name ?? 'PivotTable1',
    );
    _availableColumns = _manager.getAvailableColumns(widget.sourceSelection);
    _pivotTable = widget.existingPivotTable ??
        _manager.createPivotTable(
          id: 'pivot_${DateTime.now().millisecondsSinceEpoch}',
          name: 'PivotTable1',
          sourceSelection: widget.sourceSelection,
          targetCell: CellAddress(widget.sourceSelection.maxRow + 2, 0),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldListPanel(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLayoutPanel()),
                ],
              ),
            ),
            const Divider(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.insert_chart_outlined, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingPivotTable != null
                    ? 'Edit Pivot Table'
                    : 'Create Pivot Table',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Name: '),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFieldListPanel() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fields',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _availableColumns.length,
              itemBuilder: (context, index) {
                final column = _availableColumns[index];
                final isInPivot = _pivotTable.fields
                    .any((f) => f.sourceColumn == column);

                return Draggable<String>(
                  data: column,
                  feedback: Material(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        column,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildFieldChip(column, isInPivot),
                  ),
                  child: _buildFieldChip(column, isInPivot),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldChip(String columnName, bool isInPivot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(columnName),
        backgroundColor: isInPivot ? Colors.grey[300] : Colors.white,
        avatar: isInPivot
            ? const Icon(Icons.check_circle, size: 16, color: Colors.green)
            : null,
      ),
    );
  }

  Widget _buildLayoutPanel() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildAreaDropZone(
                  area: PivotArea.filters,
                  title: 'Filters',
                  fields: _pivotTable.filterFields,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildAreaDropZone(
                        area: PivotArea.columns,
                        title: 'Columns',
                        fields: _pivotTable.columnFields,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildAreaDropZone(
                        area: PivotArea.rows,
                        title: 'Rows',
                        fields: _pivotTable.rowFields,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildAreaDropZone(
                  area: PivotArea.values,
                  title: 'Values',
                  fields: _pivotTable.valueFields,
                  showAggregation: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAreaDropZone({
    required PivotArea area,
    required String title,
    required List<PivotField> fields,
    bool showAggregation = false,
  }) {
    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (column) {
        setState(() {
          final field = PivotField(
            sourceColumn: column,
            area: area,
            aggregation:
                area == PivotArea.values ? PivotAggregation.sum : null,
          );
          _pivotTable = _manager.addField(_pivotTable, field);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.blue[50] : Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(area.icon, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: fields.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      _pivotTable = _manager.reorderFields(
                        _pivotTable,
                        area,
                        oldIndex,
                        newIndex,
                      );
                    });
                  },
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return ListTile(
                      key: ValueKey(field.sourceColumn),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      title: Text(
                        field.displayName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: showAggregation && field.aggregation != null
                          ? Text(
                              field.aggregation!.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showAggregation)
                            PopupMenuButton<PivotAggregation>(
                              icon: const Icon(Icons.calculate, size: 18),
                              onSelected: (agg) {
                                setState(() {
                                  final updated =
                                      field.copyWith(aggregation: agg);
                                  _pivotTable = _manager.updateField(
                                    _pivotTable,
                                    index,
                                    updated,
                                  );
                                });
                              },
                              itemBuilder: (context) => [
                                for (final agg in PivotAggregation.values)
                                  PopupMenuItem(
                                    value: agg,
                                    child: Text(agg.label),
                                  ),
                              ],
                            ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            onPressed: () {
                              setState(() {
                                _pivotTable = _manager.removeField(
                                  _pivotTable,
                                  index,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Pivot Table'),
          onPressed: () {
            _pivotTable = _pivotTable.copyWith(name: _nameController.text);
            // Here you would save the pivot table to the workbook
            Navigator.of(context).pop(_pivotTable);
          },
        ),
      ],
    );
  }
}
