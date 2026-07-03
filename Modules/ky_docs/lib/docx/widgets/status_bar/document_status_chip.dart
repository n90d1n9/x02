import 'package:flutter/material.dart';

/// Displays a compact icon-and-label metric inside the document status bar.
class DocumentStatusChip extends StatelessWidget {
  static const defaultHeight = 30.0;

  final IconData icon;
  final String label;
  final String? tooltip;
  final Color? color;
  final VoidCallback? onPressed;

  const DocumentStatusChip({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.onSurfaceVariant;
    final content = Container(
      height: defaultHeight,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final tappableContent = onPressed == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: content,
            ),
          );

    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(
        button: onPressed != null,
        label: tooltip ?? label,
        child: tappableContent,
      ),
    );
  }
}

/// Shows the current save state using a compact status-bar badge.
class DocumentSaveStatusBadge extends StatelessWidget {
  final bool hasUnsavedChanges;

  const DocumentSaveStatusBadge({super.key, required this.hasUnsavedChanges});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = hasUnsavedChanges
        ? colorScheme.tertiary
        : colorScheme.primary;

    return DocumentStatusChip(
      icon: hasUnsavedChanges ? Icons.circle : Icons.check_circle,
      label: hasUnsavedChanges ? 'Unsaved' : 'Saved',
      tooltip: hasUnsavedChanges
          ? 'Document has unsaved changes'
          : 'Document is saved',
      color: color,
    );
  }
}

/// Separates status-bar metric groups without adding visual weight.
class DocumentStatusDivider extends StatelessWidget {
  const DocumentStatusDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 1,
        height: 18,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
