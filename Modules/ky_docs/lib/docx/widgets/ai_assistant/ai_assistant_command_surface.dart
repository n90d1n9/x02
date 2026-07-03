import 'package:flutter/material.dart';

import '../../models/aiaction.dart';
import 'ai_assistant_action_group.dart';
import 'ai_assistant_result_card.dart';

typedef AIAssistantActionLabelBuilder = String Function(AIAction action);
typedef AIAssistantActionIconBuilder = IconData Function(AIAction action);

/// Renders the AI writing assistant command surface independently of providers.
class AIAssistantCommandSurface extends StatelessWidget {
  static const actionPrefixKey = 'ai-assistant-action';

  final bool hasApiKey;
  final bool isProcessing;
  final String? result;
  final String contextLabel;
  final List<AIAssistantActionGroup> groups;
  final AIAssistantActionLabelBuilder actionLabelBuilder;
  final AIAssistantActionIconBuilder actionIconBuilder;
  final VoidCallback onConfigure;
  final ValueChanged<AIAction> onActionSelected;
  final VoidCallback onCopyResult;
  final VoidCallback onInsertResult;
  final VoidCallback onReplaceResult;
  final VoidCallback onClearResult;
  final VoidCallback? onClose;
  final bool showHeader;

  const AIAssistantCommandSurface({
    super.key,
    required this.hasApiKey,
    required this.isProcessing,
    required this.result,
    required this.contextLabel,
    this.groups = AIAssistantActionCatalog.groups,
    required this.actionLabelBuilder,
    required this.actionIconBuilder,
    required this.onConfigure,
    required this.onActionSelected,
    required this.onCopyResult,
    required this.onInsertResult,
    required this.onReplaceResult,
    required this.onClearResult,
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
                  if (showHeader)
                    _AIAssistantHeader(
                      hasApiKey: hasApiKey,
                      isProcessing: isProcessing,
                      contextLabel: contextLabel,
                      compact: compact,
                      onConfigure: onConfigure,
                      onClose: onClose,
                    )
                  else
                    _AIAssistantEmbeddedStatus(
                      hasApiKey: hasApiKey,
                      isProcessing: isProcessing,
                      contextLabel: contextLabel,
                      onConfigure: onConfigure,
                    ),
                  const SizedBox(height: 12),
                  if (isProcessing)
                    const _AIAssistantProcessingView()
                  else if (result != null)
                    AIAssistantResultCard(
                      result: result!,
                      onCopy: onCopyResult,
                      onInsert: onInsertResult,
                      onReplace: onReplaceResult,
                      onClear: onClearResult,
                    )
                  else
                    _AIAssistantActionGroups(
                      groups: groups,
                      hasApiKey: hasApiKey,
                      compact: compact,
                      actionLabelBuilder: actionLabelBuilder,
                      actionIconBuilder: actionIconBuilder,
                      onConfigure: onConfigure,
                      onActionSelected: onActionSelected,
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

/// Shows assistant state when an outer dock already owns the title row.
class _AIAssistantEmbeddedStatus extends StatelessWidget {
  final bool hasApiKey;
  final bool isProcessing;
  final String contextLabel;
  final VoidCallback onConfigure;

  const _AIAssistantEmbeddedStatus({
    required this.hasApiKey,
    required this.isProcessing,
    required this.contextLabel,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AIAssistantStatusChip(
          label: isProcessing
              ? 'Processing'
              : hasApiKey
              ? 'Ready'
              : 'Setup required',
          icon: isProcessing
              ? Icons.hourglass_top
              : hasApiKey
              ? Icons.check_circle_outline
              : Icons.key_outlined,
          emphasized: hasApiKey,
        ),
        _AIAssistantStatusChip(
          label: contextLabel,
          icon: Icons.short_text,
          emphasized: false,
        ),
        if (!hasApiKey)
          TextButton.icon(
            onPressed: onConfigure,
            icon: const Icon(Icons.key, size: 18),
            label: const Text('Setup'),
          ),
      ],
    );
  }
}

/// Displays assistant identity, provider status, context, and panel actions.
class _AIAssistantHeader extends StatelessWidget {
  final bool hasApiKey;
  final bool isProcessing;
  final String contextLabel;
  final bool compact;
  final VoidCallback onConfigure;
  final VoidCallback? onClose;

  const _AIAssistantHeader({
    required this.hasApiKey,
    required this.isProcessing,
    required this.contextLabel,
    required this.compact,
    required this.onConfigure,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.psychology_alt_outlined, color: colorScheme.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'AI Writing Assistant',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
    final statusChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AIAssistantStatusChip(
          label: isProcessing
              ? 'Processing'
              : hasApiKey
              ? 'Ready'
              : 'Setup required',
          icon: isProcessing
              ? Icons.hourglass_top
              : hasApiKey
              ? Icons.check_circle_outline
              : Icons.key_outlined,
          emphasized: hasApiKey,
        ),
        _AIAssistantStatusChip(
          label: contextLabel,
          icon: Icons.short_text,
          emphasized: false,
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasApiKey)
          TextButton.icon(
            onPressed: onConfigure,
            icon: const Icon(Icons.key, size: 18),
            label: const Text('Setup'),
          ),
        if (onClose != null)
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: title),
              actions,
            ],
          ),
          const SizedBox(height: 10),
          statusChips,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        statusChips,
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}

/// Shows compact status metadata for the AI assistant surface.
class _AIAssistantStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool emphasized;

  const _AIAssistantStatusChip({
    required this.label,
    required this.icon,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = emphasized
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents an in-progress state while an AI command is being processed.
class _AIAssistantProcessingView extends StatelessWidget {
  const _AIAssistantProcessingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Text('Generating suggestion...'),
          ],
        ),
      ),
    );
  }
}

/// Renders grouped AI action buttons for the assistant surface.
class _AIAssistantActionGroups extends StatelessWidget {
  final List<AIAssistantActionGroup> groups;
  final bool hasApiKey;
  final bool compact;
  final AIAssistantActionLabelBuilder actionLabelBuilder;
  final AIAssistantActionIconBuilder actionIconBuilder;
  final VoidCallback onConfigure;
  final ValueChanged<AIAction> onActionSelected;

  const _AIAssistantActionGroups({
    required this.groups,
    required this.hasApiKey,
    required this.compact,
    required this.actionLabelBuilder,
    required this.actionIconBuilder,
    required this.onConfigure,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final columns = compact ? 1 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: compact ? 3.3 : 3.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return _AIAssistantActionGroupTile(
          group: groups[index],
          hasApiKey: hasApiKey,
          actionLabelBuilder: actionLabelBuilder,
          actionIconBuilder: actionIconBuilder,
          onConfigure: onConfigure,
          onActionSelected: onActionSelected,
        );
      },
    );
  }
}

/// Displays one section of related assistant actions.
class _AIAssistantActionGroupTile extends StatelessWidget {
  final AIAssistantActionGroup group;
  final bool hasApiKey;
  final AIAssistantActionLabelBuilder actionLabelBuilder;
  final AIAssistantActionIconBuilder actionIconBuilder;
  final VoidCallback onConfigure;
  final ValueChanged<AIAction> onActionSelected;

  const _AIAssistantActionGroupTile({
    required this.group,
    required this.hasApiKey,
    required this.actionLabelBuilder,
    required this.actionIconBuilder,
    required this.onConfigure,
    required this.onActionSelected,
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
                Text(
                  group.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in group.actions)
                    _AIAssistantActionButton(
                      action: action,
                      label: actionLabelBuilder(action),
                      icon: actionIconBuilder(action),
                      onPressed: hasApiKey
                          ? () => onActionSelected(action)
                          : onConfigure,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders one assistant action as a compact command button.
class _AIAssistantActionButton extends StatelessWidget {
  final AIAction action;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _AIAssistantActionButton({
    required this.action,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: ValueKey('${AIAssistantCommandSurface.actionPrefixKey}-$action'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
