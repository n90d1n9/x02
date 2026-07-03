import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Reusable dark dialog shell for editor workflows with branded icon chrome.
class EditorDialogFrame extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget content;
  final List<Widget> actions;
  final double width;

  const EditorDialogFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.content,
    required this.actions,
    this.width = 380,
  });

  static ButtonStyle accentButtonStyle(Color accentColor) {
    return FilledButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor:
          ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
          ? Colors.white
          : Colors.black,
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
      disabledForegroundColor: Colors.white38,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      title: _EditorDialogHeader(
        title: title,
        icon: icon,
        accentColor: accentColor,
      ),
      content: SizedBox(width: width, child: content),
      actions: actions,
    );
  }
}

/// Header row used by [EditorDialogFrame] to keep dialog titles consistent.
class _EditorDialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;

  const _EditorDialogHeader({
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.38)),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Editor dialog frame', size: Size(480, 280))
Widget editorDialogFramePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorDialogFrame(
          title: 'Rename layer',
          icon: Icons.drive_file_rename_outline,
          accentColor: const Color(0xFF38BDF8),
          content: const Text(
            'Dialog content preview',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(onPressed: () {}, child: const Text('Cancel')),
            FilledButton(onPressed: () {}, child: const Text('Save')),
          ],
        ),
      ),
    ),
  );
}
