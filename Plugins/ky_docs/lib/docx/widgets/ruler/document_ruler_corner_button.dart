import 'package:flutter/material.dart';

import '../../models/page_orientation.dart';
import '../../models/page_settings.dart';
import '../../models/page_size.dart';

/// Displays the page settings affordance at the ruler intersection.
class DocumentRulerCornerButton extends StatelessWidget {
  static const buttonKey = ValueKey('document-ruler-corner-button');
  static const settingsOptionKey = ValueKey(
    'document-ruler-corner-settings-option',
  );

  final PageSettings pageSettings;
  final ValueChanged<PageSettings>? onPageSettingsChanged;
  final VoidCallback? onPressed;

  const DocumentRulerCornerButton({
    super.key,
    required this.pageSettings,
    this.onPageSettingsChanged,
    this.onPressed,
  });

  static Key pageSizeOptionKey(PageSize pageSize) {
    return Key('document-ruler-corner-page-size-${pageSize.name}');
  }

  static Key orientationOptionKey(DocumentPageOrientation orientation) {
    return Key('document-ruler-corner-orientation-${orientation.name}');
  }

  @override
  Widget build(BuildContext context) {
    final label = pageSettings.pageSize.shortLabel;
    final orientationLabel = pageSettings.orientation.label.toLowerCase();
    final enabled = onPageSettingsChanged != null || onPressed != null;
    final tooltip = enabled
        ? '${pageSettings.pageSize.label} $orientationLabel page setup'
        : '${pageSettings.pageSize.label} $orientationLabel page setup locked';

    return PopupMenuButton<_RulerCornerAction>(
      key: buttonKey,
      enabled: enabled,
      tooltip: tooltip,
      onSelected: _handleAction,
      itemBuilder: (context) => [
        for (final pageSize in PageSize.values)
          PopupMenuItem(
            key: pageSizeOptionKey(pageSize),
            value: _RulerCornerAction.pageSize(pageSize),
            enabled: onPageSettingsChanged != null,
            child: _RulerCornerMenuItem(
              icon: Icons.description_outlined,
              label: pageSize.label,
              description: _pageSizeDescription(pageSize),
              selected: pageSize == pageSettings.pageSize,
            ),
          ),
        const PopupMenuDivider(),
        for (final orientation in DocumentPageOrientation.values)
          PopupMenuItem(
            key: orientationOptionKey(orientation),
            value: _RulerCornerAction.orientation(orientation),
            enabled: onPageSettingsChanged != null,
            child: _RulerCornerMenuItem(
              icon: orientation.icon,
              label: orientation.label,
              description: '${orientation.label} page flow',
              selected: orientation == pageSettings.orientation,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: settingsOptionKey,
          value: const _RulerCornerAction.settings(),
          enabled: onPressed != null,
          child: const _RulerCornerMenuItem(
            icon: Icons.tune,
            label: 'Page settings',
            description: 'Open full setup',
            selected: false,
          ),
        ),
      ],
      child: _RulerCornerButtonBody(
        label: label,
        enabled: enabled,
        semanticLabel: tooltip,
      ),
    );
  }

  void _handleAction(_RulerCornerAction action) {
    switch (action.type) {
      case _RulerCornerActionType.pageSize:
        final pageSize = action.pageSize;
        if (pageSize == null || pageSize == pageSettings.pageSize) return;
        onPageSettingsChanged?.call(pageSettings.copyWith(pageSize: pageSize));
        break;
      case _RulerCornerActionType.orientation:
        final orientation = action.orientation;
        if (orientation == null || orientation == pageSettings.orientation) {
          return;
        }
        onPageSettingsChanged?.call(
          pageSettings.copyWith(orientation: orientation),
        );
        break;
      case _RulerCornerActionType.settings:
        onPressed?.call();
        break;
    }
  }

  String _pageSizeDescription(PageSize pageSize) {
    final size = pageSettings.copyWith(pageSize: pageSize).getPageSize();
    return '${size.width.round()} x ${size.height.round()} pt';
  }
}

/// Paints the compact page setup trigger shown at the ruler corner.
class _RulerCornerButtonBody extends StatelessWidget {
  final String label;
  final bool enabled;
  final String semanticLabel;

  const _RulerCornerButtonBody({
    required this.label,
    required this.enabled,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.58,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders one page setup menu item with selected-state affordance.
class _RulerCornerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;

  const _RulerCornerMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      children: [
        Icon(selected ? Icons.check_circle : icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identifies the selected action from the ruler corner menu.
class _RulerCornerAction {
  final _RulerCornerActionType type;
  final PageSize? pageSize;
  final DocumentPageOrientation? orientation;

  const _RulerCornerAction.pageSize(this.pageSize)
    : type = _RulerCornerActionType.pageSize,
      orientation = null;

  const _RulerCornerAction.orientation(this.orientation)
    : type = _RulerCornerActionType.orientation,
      pageSize = null;

  const _RulerCornerAction.settings()
    : type = _RulerCornerActionType.settings,
      pageSize = null,
      orientation = null;
}

/// Names the action groups available from the ruler corner menu.
enum _RulerCornerActionType { pageSize, orientation, settings }
