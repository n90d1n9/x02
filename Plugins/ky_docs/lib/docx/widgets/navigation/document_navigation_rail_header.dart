import 'package:flutter/material.dart';

import 'document_navigation_panel_close_button.dart';

/// Defines the visual emphasis used by a navigation rail count badge.
enum DocumentNavigationRailBadgeTone { primary, secondary }

/// Renders a reusable title, icon, count, and close row for workspace rails.
class DocumentNavigationRailHeader extends StatelessWidget {
  static const countBadgeKey = Key('document-navigation-rail-count-badge');

  final IconData icon;
  final String title;
  final String subtitle;
  final String countLabel;
  final DocumentNavigationRailBadgeTone badgeTone;
  final VoidCallback? onClose;
  final Key? closeButtonKey;

  const DocumentNavigationRailHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    this.badgeTone = DocumentNavigationRailBadgeTone.primary,
    this.onClose,
    this.closeButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _NavigationRailCountBadge(label: countLabel, tone: badgeTone),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            DocumentNavigationPanelCloseButton(
              key: closeButtonKey,
              onPressed: onClose!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows compact totals inside document workspace navigation rail headers.
class _NavigationRailCountBadge extends StatelessWidget {
  final String label;
  final DocumentNavigationRailBadgeTone tone;

  const _NavigationRailCountBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _colorsFor(colorScheme);

    return Container(
      key: DocumentNavigationRailHeader.countBadgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _colorsFor(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentNavigationRailBadgeTone.primary => (
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
      DocumentNavigationRailBadgeTone.secondary => (
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      ),
    };
  }
}
