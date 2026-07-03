import 'package:flutter/material.dart';

import 'panel/document_panel_text_field.dart';

/// Collects a non-empty document title for rename workflows.
class DocumentTitleDialog extends StatefulWidget {
  final String initialTitle;

  const DocumentTitleDialog({super.key, required this.initialTitle});

  static Future<String?> show(BuildContext context, {required String title}) {
    return showDialog<String>(
      context: context,
      builder: (context) => DocumentTitleDialog(initialTitle: title),
    );
  }

  @override
  State<DocumentTitleDialog> createState() => _DocumentTitleDialogState();
}

class _DocumentTitleDialogState extends State<DocumentTitleDialog> {
  late final TextEditingController _controller;
  bool _hasTitle = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle)
      ..addListener(_syncTitleState);
    _hasTitle = widget.initialTitle.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document Title'),
      content: SizedBox(
        width: 420,
        child: DocumentPanelTextField(
          controller: _controller,
          labelText: 'Title',
          hintText: 'Project proposal',
          prefixIcon: Icons.drive_file_rename_outline,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _saveTitle,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _hasTitle ? () => _saveTitle(_controller.text) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _syncTitleState() {
    final nextHasTitle = _controller.text.trim().isNotEmpty;
    if (nextHasTitle == _hasTitle) return;
    setState(() => _hasTitle = nextHasTitle);
  }

  void _saveTitle(String value) {
    final title = value.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, title);
  }
}
