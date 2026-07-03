import 'package:flutter/material.dart';

/// Renders a reusable icon-led heading for sections inside document panels.
class DocumentPanelSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double spacing;
  final int titleMaxLines;
  final int descriptionMaxLines;

  const DocumentPanelSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.padding = EdgeInsets.zero,
    this.iconSize = 17,
    this.spacing = 8,
    this.titleMaxLines = 1,
    this.descriptionMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptionText = description?.trim();
    final hasDescription =
        descriptionText != null && descriptionText.isNotEmpty;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: hasDescription
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: hasDescription
                ? const EdgeInsets.only(top: 1)
                : EdgeInsets.zero,
            child: Icon(icon, size: iconSize, color: colorScheme.primary),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 2),
                  Text(
                    descriptionText,
                    maxLines: descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
