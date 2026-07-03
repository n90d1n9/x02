import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_validation.dart';
import '../state/sheet_format_painter_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';

class QuickActionsSheet extends ConsumerWidget {
  const QuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedCellProvider);
    final formatSnapshot = ref.watch(sheetFormatPainterSnapshotProvider);
    final hasSelection = selection != null;
    final formatPainterActive = formatSnapshot != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: KySheetColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSelection
                        ? 'Quick actions for ${selection.label}'
                        : 'Select a cell or range',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: KySheetColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('Add Comment'),
            enabled: hasSelection,
            onTap: () {
              Navigator.pop(context);
              _addComment(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Insert Hyperlink'),
            enabled: hasSelection,
            onTap: () {
              Navigator.pop(context);
              _addHyperlink(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Data Validation'),
            enabled: hasSelection,
            onTap: () {
              Navigator.pop(context);
              _addValidation(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_paint),
            title: Text(
              formatPainterActive ? 'Cancel Format Painter' : 'Format Painter',
            ),
            subtitle: Text(
              formatPainterActive
                  ? 'Painting from ${formatSnapshot.sourceLabel}'
                  : 'Copy formatting to the next target range',
            ),
            enabled: hasSelection || formatPainterActive,
            onTap: () {
              Navigator.pop(context);
              _toggleFormatPainter(ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.functions),
            title: const Text('Insert Chart'),
            onTap: () {
              Navigator.pop(context);
              _showMessage(context, 'Chart feature coming soon');
            },
          ),
        ],
      ),
    );
  }

  void _addComment(BuildContext context, WidgetRef ref) {
    final selection = ref.read(selectedCellProvider);
    if (selection == null) return;

    showDialog(
      context: context,
      builder: (context) => _CommentDialog(address: selection.start),
    );
  }

  void _addHyperlink(BuildContext context, WidgetRef ref) {
    final selection = ref.read(selectedCellProvider);
    if (selection == null) return;

    showDialog(
      context: context,
      builder: (context) => _HyperlinkDialog(address: selection.start),
    );
  }

  void _addValidation(BuildContext context, WidgetRef ref) {
    final selection = ref.read(selectedCellProvider);
    if (selection == null) return;

    showDialog(
      context: context,
      builder: (context) => _ValidationDialog(address: selection.start),
    );
  }

  void _toggleFormatPainter(WidgetRef ref) {
    final controller = ref.read(sheetFormatPainterControllerProvider);
    if (controller.isActive) {
      controller.cancel();
      return;
    }

    final selection = ref.read(selectedCellProvider);
    if (selection == null) return;

    controller.start(selection);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CommentDialog extends ConsumerStatefulWidget {
  final CellAddress address;

  const _CommentDialog({required this.address});

  @override
  ConsumerState<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends ConsumerState<_CommentDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(spreadsheetProvider);
    _controller.text = data[widget.address]?.comment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Comment for ${widget.address.label}'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter comment',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final comment = _controller.text.trim();
            final data = ref.read(spreadsheetProvider);
            final current = data[widget.address] ?? CellData();
            ref
                .read(spreadsheetProvider.notifier)
                .updateCell(
                  widget.address,
                  comment.isEmpty
                      ? current.copyWith(clearComment: true)
                      : current.copyWith(comment: comment),
                );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _HyperlinkDialog extends ConsumerStatefulWidget {
  final CellAddress address;

  const _HyperlinkDialog({required this.address});

  @override
  ConsumerState<_HyperlinkDialog> createState() => _HyperlinkDialogState();
}

class _HyperlinkDialogState extends ConsumerState<_HyperlinkDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(spreadsheetProvider);
    _controller.text = data[widget.address]?.hyperlink ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hyperlink for ${widget.address.label}'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'https://example.com',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final hyperlink = _controller.text.trim();
            final data = ref.read(spreadsheetProvider);
            final current = data[widget.address] ?? CellData();
            ref
                .read(spreadsheetProvider.notifier)
                .updateCell(
                  widget.address,
                  hyperlink.isEmpty
                      ? current.copyWith(clearHyperlink: true)
                      : current.copyWith(hyperlink: hyperlink),
                );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ValidationDialog extends ConsumerStatefulWidget {
  final CellAddress address;

  const _ValidationDialog({required this.address});

  @override
  ConsumerState<_ValidationDialog> createState() => _ValidationDialogState();
}

class _ValidationDialogState extends ConsumerState<_ValidationDialog> {
  ValidationType _type = ValidationType.none;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _optionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Data Validation for ${widget.address.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ValidationType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Validation Type'),
            items: ValidationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _type = value!),
          ),
          if (_type == ValidationType.number) ...[
            TextField(
              controller: _minController,
              decoration: const InputDecoration(labelText: 'Min Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _maxController,
              decoration: const InputDecoration(labelText: 'Max Value'),
              keyboardType: TextInputType.number,
            ),
          ],
          if (_type == ValidationType.list)
            TextField(
              controller: _optionsController,
              decoration: const InputDecoration(
                labelText: 'Options (comma-separated)',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final validation = CellValidation(
              type: _type,
              min: _minController.text.isEmpty ? null : _minController.text,
              max: _maxController.text.isEmpty ? null : _maxController.text,
              options: _type == ValidationType.list
                  ? _optionsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList()
                  : null,
            );

            final data = ref.read(spreadsheetProvider);
            final current = data[widget.address] ?? CellData();
            ref
                .read(spreadsheetProvider.notifier)
                .updateCell(
                  widget.address,
                  current.copyWith(validation: validation),
                );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _optionsController.dispose();
    super.dispose();
  }
}
