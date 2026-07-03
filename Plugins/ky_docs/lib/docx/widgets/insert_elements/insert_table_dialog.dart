import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/provider.dart';
import '../panel/document_panel_section_header.dart';
import '../panel/document_panel_slider_control.dart';

/// Lets users choose a starting table grid before inserting it in the document.
class InsertTableDialog extends ConsumerStatefulWidget {
  static const rowsSliderKey = ValueKey('insert-table-rows-slider');
  static const columnsSliderKey = ValueKey('insert-table-columns-slider');

  const InsertTableDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const InsertTableDialog(),
    );
  }

  @override
  ConsumerState<InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends ConsumerState<InsertTableDialog> {
  int _rows = 3;
  int _columns = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Table'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DocumentPanelSectionHeader(
              icon: Icons.table_chart_outlined,
              title: 'Table size',
              description: 'Choose the starting grid for the inserted table.',
            ),
            const SizedBox(height: 14),
            DocumentPanelSliderControl(
              sliderKey: InsertTableDialog.rowsSliderKey,
              icon: Icons.view_stream_outlined,
              label: 'Rows',
              valueLabel: '$_rows',
              description: 'Vertical cells in the table.',
              value: _rows.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              semanticFormatterSuffix: 'rows',
              onChanged: (value) => setState(() => _rows = value.round()),
            ),
            const SizedBox(height: 10),
            DocumentPanelSliderControl(
              sliderKey: InsertTableDialog.columnsSliderKey,
              icon: Icons.view_column_outlined,
              label: 'Columns',
              valueLabel: '$_columns',
              description: 'Horizontal cells in each row.',
              value: _columns.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              semanticFormatterSuffix: 'columns',
              onChanged: (value) => setState(() => _columns = value.round()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _insertTable, child: const Text('Insert')),
      ],
    );
  }

  void _insertTable() {
    final messenger = ScaffoldMessenger.of(context);

    ref.read(documentProvider.notifier).insertTable(_rows, _columns);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Table (${_rows}x$_columns) inserted')),
    );
  }
}
