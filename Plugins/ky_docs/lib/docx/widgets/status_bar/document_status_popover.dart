import 'package:flutter/material.dart';

/// Provides a compact, reusable shell for status-bar detail popovers.
class DocumentStatusPopover extends StatelessWidget {
  final Key? contentKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final double width;
  final List<Widget> children;

  const DocumentStatusPopover({
    super.key,
    this.contentKey,
    required this.icon,
    required this.title,
    this.subtitle,
    this.width = 280,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      key: contentKey,
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Shows one label/value row inside a compact status-bar popover.
class DocumentStatusPopoverMetricLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DocumentStatusPopoverMetricLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a full-width action inside a status-bar detail popover.
class DocumentStatusPopoverActionButton extends StatelessWidget {
  final Key? actionKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const DocumentStatusPopoverActionButton({
    super.key,
    this.actionKey,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: actionKey,
          icon: Icon(icon, size: 16),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
