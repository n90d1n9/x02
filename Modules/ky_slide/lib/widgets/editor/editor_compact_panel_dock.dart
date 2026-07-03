import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Action metadata for a panel that can be opened from the compact editor dock.
class EditorCompactPanelDockItem {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const EditorCompactPanelDockItem({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}

/// Floating compact dock for reaching panels that are hidden by responsive layout.
class EditorCompactPanelDock extends StatelessWidget {
  final List<EditorCompactPanelDockItem> items;
  final Color accentColor;

  const EditorCompactPanelDock({
    super.key,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF111827).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(8),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                _EditorCompactPanelDockButton(
                  item: item,
                  accentColor: accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon button used by the compact panel dock.
class _EditorCompactPanelDockButton extends StatelessWidget {
  final EditorCompactPanelDockItem item;
  final Color accentColor;

  const _EditorCompactPanelDockButton({
    required this.item,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.tooltip,
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: accentColor.withValues(alpha: 0.16),
          hoverColor: accentColor.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: Icon(item.icon, size: 19),
        onPressed: item.onPressed,
      ),
    );
  }
}

@Preview(name: 'Editor compact panel dock', size: Size(180, 90))
Widget editorCompactPanelDockPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorCompactPanelDock(
          accentColor: const Color(0xFF38BDF8),
          items: [
            EditorCompactPanelDockItem(
              icon: Icons.view_carousel_outlined,
              tooltip: 'Open slide navigator panel',
              onPressed: () {},
            ),
            EditorCompactPanelDockItem(
              icon: Icons.tune,
              tooltip: 'Open inspector panel',
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
