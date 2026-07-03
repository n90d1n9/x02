import 'package:flutter/material.dart';

import 'insert_element_command.dart';

/// Renders grouped document insert commands as a reusable editor surface.
class InsertElementsHub extends StatelessWidget {
  static const commandPrefixKey = 'insert-elements-command';
  static const closeButtonKey = ValueKey('insert-elements-close');

  final List<InsertElementCommandGroup> groups;
  final ValueChanged<InsertElementCommandId> onCommandSelected;
  final VoidCallback? onClose;
  final bool showHeader;

  const InsertElementsHub({
    super.key,
    this.groups = InsertElementCommandCatalog.groups,
    required this.onCommandSelected,
    this.onClose,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    _InsertHubHeader(onClose: onClose),
                    const SizedBox(height: 14),
                  ],
                  _InsertCommandGroups(
                    groups: groups,
                    compact: compact,
                    onCommandSelected: onCommandSelected,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Displays the title and close affordance for the insert hub.
class _InsertHubHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _InsertHubHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.add_box_outlined, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Insert',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onClose != null)
          IconButton(
            key: InsertElementsHub.closeButtonKey,
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
      ],
    );
  }
}

/// Lays out insert command groups responsively for editor widths.
class _InsertCommandGroups extends StatelessWidget {
  final List<InsertElementCommandGroup> groups;
  final bool compact;
  final ValueChanged<InsertElementCommandId> onCommandSelected;

  const _InsertCommandGroups({
    required this.groups,
    required this.compact,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            _InsertCommandGroupCard(
              group: groups[index],
              onCommandSelected: onCommandSelected,
            ),
            if (index < groups.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          Expanded(
            child: _InsertCommandGroupCard(
              group: groups[index],
              onCommandSelected: onCommandSelected,
            ),
          ),
          if (index < groups.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// Displays one group of related insert commands.
class _InsertCommandGroupCard extends StatelessWidget {
  final InsertElementCommandGroup group;
  final ValueChanged<InsertElementCommandId> onCommandSelected;

  const _InsertCommandGroupCard({
    required this.group,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(group.icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final command in group.commands)
                  _InsertCommandButton(
                    command: command,
                    onPressed: () => onCommandSelected(command.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a single insert command as an ergonomic chip button.
class _InsertCommandButton extends StatelessWidget {
  final InsertElementCommand command;
  final VoidCallback onPressed;

  const _InsertCommandButton({required this.command, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: ValueKey('${InsertElementsHub.commandPrefixKey}-${command.id}'),
      avatar: Icon(command.icon, size: 18),
      label: Text(command.label),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
