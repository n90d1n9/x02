import 'package:flutter/material.dart';

/// Dialog for renaming a workbook sheet.
class SheetRenameDialog extends StatefulWidget {
  const SheetRenameDialog({super.key, required this.initialName});

  /// Current sheet name shown when the dialog opens.
  final String initialName;

  @override
  State<SheetRenameDialog> createState() => _SheetRenameDialogState();
}

/// Owns the rename text controller for the lifetime of the dialog route.
class _SheetRenameDialogState extends State<SheetRenameDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Sheet'),
      content: TextField(
        key: const ValueKey('ky-sheet-rename-name'),
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Sheet name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('ky-sheet-rename-confirm'),
          onPressed: () => _submit(_textController.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }

  void _submit(String value) {
    Navigator.of(context).pop(value);
  }
}
