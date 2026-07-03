import 'package:flutter/material.dart';

import '../panel/document_panel_text_field.dart';

/// Collects footnote text for adding or editing a document note.
class FootnoteTextDialog extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String initialText;

  const FootnoteTextDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialText = '',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    String initialText = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => FootnoteTextDialog(
        title: title,
        actionLabel: actionLabel,
        initialText: initialText,
      ),
    );
  }

  @override
  State<FootnoteTextDialog> createState() => _FootnoteTextDialogState();
}

class _FootnoteTextDialogState extends State<FootnoteTextDialog> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText)
      ..addListener(_syncTextState);
    _hasText = widget.initialText.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: DocumentPanelTextField(
          controller: _controller,
          labelText: 'Footnote text',
          hintText: 'Add citation details, source context, or an aside.',
          prefixIcon: Icons.notes_outlined,
          maxLines: 4,
          minLines: 3,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _hasText ? _submit : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }

  void _syncTextState() {
    final nextHasText = _controller.text.trim().isNotEmpty;
    if (nextHasText == _hasText) return;
    setState(() => _hasText = nextHasText);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }
}
