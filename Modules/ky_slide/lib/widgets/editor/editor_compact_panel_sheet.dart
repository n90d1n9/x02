import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Modal panel frame used when responsive layout moves editor side panels off canvas.
class EditorCompactPanelSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose;

  const EditorCompactPanelSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _EditorCompactPanelSheetHeader(
            title: title,
            icon: icon,
            onClose: onClose,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Header chrome for compact editor panel sheets.
class _EditorCompactPanelSheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClose;

  const _EditorCompactPanelSheetHeader({
    required this.title,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Tooltip(
            message: 'Close panel',
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.white70,
              onPressed: onClose,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

@Preview(name: 'Editor compact panel sheet', size: Size(420, 520))
Widget editorCompactPanelSheetPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 380,
          height: 460,
          child: EditorCompactPanelSheet(
            title: 'Slide navigator',
            icon: Icons.view_carousel_outlined,
            onClose: () {},
            child: const Center(
              child: Text(
                'Panel content',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
