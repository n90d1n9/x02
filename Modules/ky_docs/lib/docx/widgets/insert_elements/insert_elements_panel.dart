import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/provider.dart';
import '../drawing_tools.dart';
import '../footnotes/footnote_text_dialog.dart';
import 'insert_chart_dialog.dart';
import 'insert_element_command.dart';
import 'insert_elements_hub.dart';
import 'insert_table_dialog.dart';

/// Connects document insert commands to the reusable insert hub surface.
class InsertElementsPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool showHeader;

  const InsertElementsPanel({super.key, this.onClose, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InsertElementsHub(
      onClose: onClose,
      showHeader: showHeader,
      onCommandSelected: (command) {
        _handleCommand(context, ref, command);
      },
    );
  }

  Future<void> _handleCommand(
    BuildContext context,
    WidgetRef ref,
    InsertElementCommandId command,
  ) async {
    switch (command) {
      case InsertElementCommandId.table:
        await InsertTableDialog.show(context);
      case InsertElementCommandId.chart:
        await InsertChartDialog.show(context);
      case InsertElementCommandId.image:
        await _insertImage(context, ref);
      case InsertElementCommandId.drawing:
        await _showDrawingDialog(context);
      case InsertElementCommandId.footnote:
        await _addFootnote(context, ref);
      case InsertElementCommandId.rectangle:
        await _insertShape(context, ref, 'rectangle', 'Rectangle');
      case InsertElementCommandId.circle:
        await _insertShape(context, ref, 'circle', 'Circle');
      case InsertElementCommandId.triangle:
        await _insertShape(context, ref, 'triangle', 'Triangle');
      case InsertElementCommandId.star:
        await _insertShape(context, ref, 'star', 'Star');
    }
  }

  Future<void> _insertImage(BuildContext context, WidgetRef ref) async {
    await ref.read(documentProvider.notifier).insertImage();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image insertion is a placeholder feature')),
    );
  }

  Future<void> _showDrawingDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const DocxDrawingDialog(),
    );
  }

  Future<void> _addFootnote(BuildContext context, WidgetRef ref) async {
    final text = await FootnoteTextDialog.show(
      context,
      title: 'Add Footnote',
      actionLabel: 'Add',
    );
    if (text == null || text.trim().isEmpty) return;
    ref.read(documentProvider.notifier).addFootnote(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Footnote added')));
  }

  Future<void> _insertShape(
    BuildContext context,
    WidgetRef ref,
    String shape,
    String label,
  ) async {
    await ref.read(documentProvider.notifier).insertShape(shape);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label inserted')));
  }
}
