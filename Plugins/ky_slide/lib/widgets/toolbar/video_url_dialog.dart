import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../dialogs/editor_dialog_frame.dart';
import '../dialogs/editor_dialog_text_field.dart';

/// Modal editor for collecting a video URL before inserting media on a slide.
class VideoUrlDialog extends StatefulWidget {
  final Color accentColor;
  final String initialUrl;
  final ValueChanged<String> onSubmitted;

  const VideoUrlDialog({
    super.key,
    required this.onSubmitted,
    this.accentColor = const Color(0xFFF59E0B),
    this.initialUrl = '',
  });

  @override
  State<VideoUrlDialog> createState() => _VideoUrlDialogState();
}

/// Stateful controller layer for validating and submitting the video URL draft.
class _VideoUrlDialogState extends State<VideoUrlDialog> {
  late final TextEditingController _controller;

  String get _trimmedUrl => _controller.text.trim();

  bool get _canSubmit => _trimmedUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
    _controller.addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDraftChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    setState(() {});
  }

  void _submit() {
    final url = _trimmedUrl;
    if (url.isEmpty) return;

    widget.onSubmitted(url);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialogFrame(
      title: 'Add video',
      icon: Icons.videocam,
      accentColor: widget.accentColor,
      content: EditorDialogTextField(
        controller: _controller,
        labelText: 'Video URL',
        hintText: 'YouTube, Vimeo, Loom, or direct URL',
        prefixIcon: Icons.link,
        accentColor: widget.accentColor,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          style: EditorDialogFrame.accentButtonStyle(widget.accentColor),
          icon: const Icon(Icons.add_link, size: 16),
          label: const Text('Add video'),
        ),
      ],
    );
  }
}

@Preview(name: 'Video URL dialog', size: Size(480, 300))
Widget videoUrlDialogPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(child: VideoUrlDialog(onSubmitted: (_) {})),
    ),
  );
}
