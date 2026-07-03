import 'package:flutter/material.dart';

/// Defines the color treatment used by compact document panel summaries.
enum DocumentPanelSummaryTone { primary, error, neutral }

/// Renders a reusable icon, title, subtitle, and optional action summary card.
class DocumentPanelSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final DocumentPanelSummaryTone tone;
  final Widget? trailing;

  const DocumentPanelSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = DocumentPanelSummaryTone.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _colorsFor(colorScheme);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: colors.backgroundAlpha),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.border.withValues(alpha: colors.borderAlpha),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }

  ({
    Color background,
    Color border,
    Color icon,
    double backgroundAlpha,
    double borderAlpha,
  })
  _colorsFor(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentPanelSummaryTone.primary => (
        background: colorScheme.primary,
        border: colorScheme.primary,
        icon: colorScheme.primary,
        backgroundAlpha: 0.08,
        borderAlpha: 0.16,
      ),
      DocumentPanelSummaryTone.error => (
        background: colorScheme.errorContainer,
        border: colorScheme.error,
        icon: colorScheme.error,
        backgroundAlpha: 0.25,
        borderAlpha: 0.18,
      ),
      DocumentPanelSummaryTone.neutral => (
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
        icon: colorScheme.primary,
        backgroundAlpha: 0.36,
        borderAlpha: 1,
      ),
    };
  }
}
