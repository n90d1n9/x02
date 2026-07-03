import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../dialogs/editor_dialog_frame.dart';
import '../dialogs/editor_dialog_text_field.dart';

/// Modal editor for applying a custom label to a slide layer.
class LayerRenameDialog extends StatefulWidget {
  final String initialName;
  final String fallbackName;
  final Color accentColor;
  final ValueChanged<String?> onRename;

  const LayerRenameDialog({
    super.key,
    required this.initialName,
    required this.fallbackName,
    required this.accentColor,
    required this.onRename,
  });

  @override
  State<LayerRenameDialog> createState() => _LayerRenameDialogState();
}

/// Stateful controller layer for editing and submitting a layer name draft.
class _LayerRenameDialogState extends State<LayerRenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialogFrame(
      title: 'Rename layer',
      icon: Icons.drive_file_rename_outline,
      accentColor: widget.accentColor,
      width: 360,
      content: EditorDialogTextField(
        controller: _controller,
        labelText: 'Layer name',
        hintText: widget.fallbackName,
        prefixIcon: Icons.layers_outlined,
        accentColor: widget.accentColor,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onRename(null);
          },
          style: TextButton.styleFrom(foregroundColor: widget.accentColor),
          child: const Text('Use content'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: EditorDialogFrame.accentButtonStyle(widget.accentColor),
          child: const Text('Rename'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop();
    widget.onRename(_controller.text);
  }
}

@Preview(name: 'Layer rename dialog', size: Size(460, 300))
Widget layerRenameDialogPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: LayerRenameDialog(
          initialName: 'Hero title',
          fallbackName: 'Text layer',
          accentColor: const Color(0xFF38BDF8),
          onRename: (_) {},
        ),
      ),
    ),
  );
}
