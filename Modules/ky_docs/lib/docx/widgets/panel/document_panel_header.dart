import 'package:flutter/material.dart';

/// Renders the standard icon, title, subtitle, and close affordance for panels.
class DocumentPanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;
  final String closeTooltip;
  final Key? closeButtonKey;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  const DocumentPanelHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onClose,
    this.closeTooltip = 'Close panel',
    this.closeButtonKey,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 8, 10),
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              key: closeButtonKey,
              tooltip: closeTooltip,
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
