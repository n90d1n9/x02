import 'package:flutter/material.dart';

/// Dialog for renaming a structured table header with inline validation.
class SheetTableHeaderRenameDialog extends StatefulWidget {
  const SheetTableHeaderRenameDialog({
    super.key,
    required this.initialName,
    required this.validator,
  });

  /// Header name shown when the dialog opens.
  final String initialName;

  /// Validates the proposed header name before the dialog returns it.
  final String? Function(String value) validator;

  @override
  State<SheetTableHeaderRenameDialog> createState() =>
      _SheetTableHeaderRenameDialogState();
}

/// Owns the text editing state for the table header rename route.
class _SheetTableHeaderRenameDialogState
    extends State<SheetTableHeaderRenameDialog> {
  late final TextEditingController _textController;
  String? _errorText;

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
      title: const Text('Rename Header'),
      content: TextField(
        key: const ValueKey('ky-sheet-table-header-rename-name'),
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Header name',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText == null) return;
          setState(() => _errorText = null);
        },
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('ky-sheet-table-header-rename-confirm'),
          onPressed: () => _submit(_textController.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }

  void _submit(String value) {
    final trimmed = value.trim();
    final errorText = widget.validator(trimmed);
    if (errorText != null) {
      setState(() => _errorText = errorText);
      return;
    }

    Navigator.of(context).pop(trimmed);
  }
}
