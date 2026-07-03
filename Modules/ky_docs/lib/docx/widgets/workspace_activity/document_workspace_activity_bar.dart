import 'package:flutter/material.dart';

import 'document_workspace_activity_item.dart';

/// Renders a compact workspace rail for frequently used document panels.
class DocumentWorkspaceActivityBar extends StatelessWidget {
  static const barKey = ValueKey('document-workspace-activity-bar');
  static const width = 56.0;

  final List<DocumentWorkspaceActivityGroup> groups;

  const DocumentWorkspaceActivityBar({super.key, required this.groups});

  static Key itemKey(DocumentWorkspaceActivityId id) {
    return ValueKey('document-workspace-activity-${id.name}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'Workspace shortcuts',
      child: DecoratedBox(
        key: barKey,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
          border: Border(
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.56),
            ),
          ),
        ),
        child: SizedBox(
          width: width,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
              child: Column(
                children: [
                  for (var index = 0; index < groups.length; index++) ...[
                    _ActivityGroup(group: groups[index]),
                    if (index < groups.length - 1)
                      const _ActivityGroupDivider(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out one semantic group of workspace activity actions.
class _ActivityGroup extends StatelessWidget {
  final DocumentWorkspaceActivityGroup group;

  const _ActivityGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: group.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in group.items) ...[
            _ActivityButton(item: item),
            if (item != group.items.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

/// Draws a fixed-size icon action with active and disabled treatments.
class _ActivityButton extends StatelessWidget {
  final DocumentWorkspaceActivityItem item;

  const _ActivityButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = item.enabled
        ? item.active
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final tooltip = item.enabled
        ? item.tooltip
        : item.disabledTooltip ?? item.tooltip;

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: item.active ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          IconButton(
            key: DocumentWorkspaceActivityBar.itemKey(item.id),
            isSelected: item.active,
            selectedIcon: Icon(item.selectedIcon),
            icon: Icon(item.icon),
            tooltip: tooltip,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size.square(38)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (!item.active || states.contains(WidgetState.disabled)) {
                  return null;
                }
                return colorScheme.primaryContainer.withValues(alpha: 0.88);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return colorScheme.onSurface.withValues(alpha: 0.38);
                }
                return foreground;
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            onPressed: item.enabled ? item.onPressed : null,
          ),
        ],
      ),
    );
  }
}

/// Separates activity groups without adding visual weight to the rail.
class _ActivityGroupDivider extends StatelessWidget {
  const _ActivityGroupDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 24,
        child: Divider(
          height: 1,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}
