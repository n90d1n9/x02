import 'package:flutter/material.dart';

/// Reusable keyboard shortcut chip for menus, panels, and command surfaces.
class SheetShortcutHint extends StatelessWidget {
  const SheetShortcutHint({super.key, required this.label, this.dense = true});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final foreground =
        defaultStyle.color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.06),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(dense ? 5 : 6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 5 : 7,
          vertical: dense ? 2 : 4,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: defaultStyle.copyWith(
            color: foreground.withValues(alpha: 0.72),
            fontSize: dense ? 10 : 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
