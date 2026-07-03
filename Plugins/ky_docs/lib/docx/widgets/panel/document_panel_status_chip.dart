import 'package:flutter/material.dart';

/// Defines the semantic color treatment for panel status chips.
enum DocumentPanelStatusTone { primary, warning, danger, neutral }

/// Renders a compact rounded status label inside document side panels.
class DocumentPanelStatusChip extends StatelessWidget {
  final String label;
  final DocumentPanelStatusTone tone;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const DocumentPanelStatusChip({
    super.key,
    required this.label,
    this.tone = DocumentPanelStatusTone.neutral,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForTone(Theme.of(context).colorScheme);
    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final message = tooltip;
    if (message == null) return chip;
    return Tooltip(message: message, child: chip);
  }

  Color _colorForTone(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentPanelStatusTone.primary => colorScheme.primary,
      DocumentPanelStatusTone.warning => colorScheme.tertiary,
      DocumentPanelStatusTone.danger => colorScheme.error,
      DocumentPanelStatusTone.neutral => colorScheme.onSurfaceVariant,
    };
  }
}
