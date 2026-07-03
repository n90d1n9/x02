import 'package:flutter/material.dart';

class SlideThumbnailQuickActions extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final bool canDelete;
  final VoidCallback? onDeleteUnavailable;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;

  const SlideThumbnailQuickActions({
    super.key,
    required this.accentColor,
    required this.onDuplicate,
    required this.onDelete,
    this.canDelete = true,
    this.onDeleteUnavailable,
    this.onMoveUp,
    this.onMoveDown,
    this.canMoveUp = false,
    this.canMoveDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuickActionButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: canMoveUp ? 'Move slide up' : 'Already first slide',
            accentColor: accentColor,
            onPressed: canMoveUp ? onMoveUp : null,
          ),
          _QuickActionButton(
            icon: Icons.keyboard_arrow_down,
            tooltip: canMoveDown ? 'Move slide down' : 'Already last slide',
            accentColor: accentColor,
            onPressed: canMoveDown ? onMoveDown : null,
          ),
          _QuickActionButton(
            icon: Icons.content_copy,
            tooltip: 'Duplicate slide',
            accentColor: accentColor,
            onPressed: onDuplicate,
          ),
          _QuickActionButton(
            icon: canDelete ? Icons.delete_outline : Icons.lock_outline,
            tooltip: canDelete
                ? 'Delete slide'
                : 'Presentation needs at least one slide',
            accentColor: canDelete ? Colors.redAccent : Colors.amberAccent,
            onPressed: canDelete ? onDelete : onDeleteUnavailable,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: 25,
      height: 25,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 25, height: 25),
        iconSize: 15,
        color: enabled ? Colors.white : Colors.white30,
        hoverColor: accentColor.withValues(alpha: 0.18),
        focusColor: accentColor.withValues(alpha: 0.16),
        splashColor: accentColor.withValues(alpha: 0.20),
        disabledColor: Colors.white30,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
