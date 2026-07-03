import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Layer ordering actions exposed by the selected-object context toolbar.
enum SelectionContextLayerOrderAction {
  bringForward,
  bringToFront,
  sendBackward,
  sendToBack,
}

/// Reusable floating action bar for the currently selected slide object.
class SelectionContextActionBar extends StatelessWidget {
  static const double visualWidth = 252;
  static const double visualHeight = 40;

  final bool isLocked;
  final Color accentColor;
  final VoidCallback? onDuplicate;
  final ValueChanged<SelectionContextLayerOrderAction>? onLayerOrderSelected;
  final Widget? arrangeMenu;
  final Widget? quickFormatMenu;
  final VoidCallback? onOpenProperties;
  final VoidCallback onToggleLock;
  final VoidCallback? onDelete;

  const SelectionContextActionBar({
    super.key,
    required this.isLocked,
    required this.accentColor,
    required this.onDuplicate,
    required this.onLayerOrderSelected,
    this.arrangeMenu,
    this.quickFormatMenu,
    required this.onOpenProperties,
    required this.onToggleLock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = !isLocked;

    return Container(
      width: visualWidth,
      height: visualHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectionContextActionButton(
            icon: Icons.control_point_duplicate,
            tooltip: 'Duplicate selected object',
            accentColor: accentColor,
            onPressed: canEdit ? onDuplicate : null,
          ),
          _SelectionLayerOrderMenu(
            accentColor: accentColor,
            enabled: canEdit && onLayerOrderSelected != null,
            onSelected: onLayerOrderSelected,
          ),
          ?arrangeMenu,
          ?quickFormatMenu,
          _SelectionContextActionButton(
            icon: Icons.tune,
            tooltip: 'Open object properties',
            accentColor: accentColor,
            onPressed: onOpenProperties,
          ),
          _SelectionContextActionButton(
            icon: isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
            tooltip: isLocked
                ? 'Unlock selected object'
                : 'Lock selected object',
            accentColor: accentColor,
            onPressed: onToggleLock,
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          _SelectionContextActionButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete selected object',
            accentColor: const Color(0xFFEF4444),
            onPressed: canEdit ? onDelete : null,
          ),
        ],
      ),
    );
  }
}

/// Popup command for moving the selected object within the layer stack.
class _SelectionLayerOrderMenu extends StatelessWidget {
  final Color accentColor;
  final bool enabled;
  final ValueChanged<SelectionContextLayerOrderAction>? onSelected;

  const _SelectionLayerOrderMenu({
    required this.accentColor,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accentColor : Colors.white24;

    return PopupMenuButton<SelectionContextLayerOrderAction>(
      tooltip: 'Layer order',
      enabled: enabled,
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, 34),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: SelectionContextLayerOrderAction.bringForward,
          child: _SelectionLayerOrderMenuItem(
            icon: Icons.keyboard_arrow_up,
            label: 'Bring forward',
          ),
        ),
        PopupMenuItem(
          value: SelectionContextLayerOrderAction.bringToFront,
          child: _SelectionLayerOrderMenuItem(
            icon: Icons.vertical_align_top,
            label: 'Bring to front',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: SelectionContextLayerOrderAction.sendBackward,
          child: _SelectionLayerOrderMenuItem(
            icon: Icons.keyboard_arrow_down,
            label: 'Send backward',
          ),
        ),
        PopupMenuItem(
          value: SelectionContextLayerOrderAction.sendToBack,
          child: _SelectionLayerOrderMenuItem(
            icon: Icons.vertical_align_bottom,
            label: 'Send to back',
          ),
        ),
      ],
      child: _SelectionContextIconShell(
        icon: Icons.layers_outlined,
        color: color,
      ),
    );
  }
}

/// Icon and label row used inside the layer-order popup menu.
class _SelectionLayerOrderMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SelectionLayerOrderMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Icon-only command button used by the selected-object action bar.
class _SelectionContextActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _SelectionContextActionButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(7),
          child: _SelectionContextIconShell(
            icon: icon,
            color: enabled ? accentColor : Colors.white24,
          ),
        ),
      ),
    );
  }
}

/// Stable icon hit target shared by toolbar buttons and menu triggers.
class _SelectionContextIconShell extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SelectionContextIconShell({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Icon(icon, size: 17, color: color),
    );
  }
}

@Preview(name: 'Selection context action bar', size: Size(260, 120))
Widget selectionContextActionBarPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SelectionContextActionBar(
          isLocked: false,
          accentColor: const Color(0xFF38BDF8),
          onDuplicate: () {},
          onLayerOrderSelected: (_) {},
          arrangeMenu: _SelectionContextActionButton(
            icon: Icons.align_horizontal_center,
            tooltip: 'Align selected object',
            accentColor: const Color(0xFF38BDF8),
            onPressed: () {},
          ),
          quickFormatMenu: _SelectionContextActionButton(
            icon: Icons.format_paint_outlined,
            tooltip: 'Quick format',
            accentColor: const Color(0xFF38BDF8),
            onPressed: () {},
          ),
          onOpenProperties: () {},
          onToggleLock: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
}
