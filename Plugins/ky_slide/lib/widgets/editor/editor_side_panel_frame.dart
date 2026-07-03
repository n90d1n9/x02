import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Side where an editor support panel is docked.
enum EditorSidePanelSide { left, right }

/// Reusable frame for docked editor side panels with directional shadowing.
class EditorSidePanelFrame extends StatelessWidget {
  final double width;
  final EditorSidePanelSide side;
  final Widget child;

  const EditorSidePanelFrame({
    super.key,
    required this.width,
    required this.side,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          left: side == EditorSidePanelSide.right
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
          right: side == EditorSidePanelSide.left
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: side == EditorSidePanelSide.left
                ? const Offset(2, 0)
                : const Offset(-2, 0),
          ),
        ],
      ),
      child: child,
    );
  }
}

@Preview(name: 'Editor side panel frame', size: Size(320, 420))
Widget editorSidePanelFramePreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorSidePanelFrame(
          width: 260,
          side: EditorSidePanelSide.left,
          child: Center(
            child: Text(
              'Panel content',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
