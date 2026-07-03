import 'package:flutter/material.dart';

import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_header.dart';
import '../panel/document_panel_search_field.dart';
import '../panel/document_panel_section_header.dart';
import 'document_more_options_filter.dart';
import 'document_more_option.dart';

/// Renders grouped document tools for the editor more-options sheet.
class DocumentMoreOptionsPanel extends StatefulWidget {
  static const optionPrefixKey = 'document-more-option';
  static const closeButtonKey = ValueKey('document-more-options-close');
  static const searchFieldKey = ValueKey('document-more-options-search');
  static const clearSearchButtonKey = ValueKey(
    'document-more-options-clear-search',
  );

  final List<DocumentMoreOptionGroup> groups;
  final ValueChanged<DocumentMoreOptionId> onOptionSelected;
  final VoidCallback? onClose;

  const DocumentMoreOptionsPanel({
    super.key,
    required this.groups,
    required this.onOptionSelected,
    this.onClose,
  });

  @override
  State<DocumentMoreOptionsPanel> createState() =>
      _DocumentMoreOptionsPanelState();
}

class _DocumentMoreOptionsPanelState extends State<DocumentMoreOptionsPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filter = DocumentMoreOptionsFilter(
      groups: widget.groups,
      query: _searchController.text,
    );
    final visibleGroups = filter.visibleGroups;

    return SafeArea(
      top: false,
      child: Material(
        color: colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DocumentPanelHeader(
                icon: Icons.tune_outlined,
                title: 'Document tools',
                subtitle: filter.summary,
                closeTooltip: 'Close document tools',
                closeButtonKey: DocumentMoreOptionsPanel.closeButtonKey,
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                onClose: widget.onClose,
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              if (widget.groups.isNotEmpty)
                DocumentPanelSearchField(
                  fieldKey: DocumentMoreOptionsPanel.searchFieldKey,
                  clearButtonKey: DocumentMoreOptionsPanel.clearSearchButtonKey,
                  controller: _searchController,
                  hintText: 'Search tools',
                  onChanged: (_) => setState(() {}),
                  onClear: _clearSearch,
                  hasQuery: filter.hasQuery,
                  clearTooltip: 'Clear tools search',
                  tone: DocumentPanelSearchFieldTone.container,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 40,
                  borderRadius: 10,
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.groups.isEmpty ? 14 : 6,
                    16,
                    18,
                  ),
                  child: widget.groups.isEmpty
                      ? const _EmptyMoreOptionsState()
                      : visibleGroups.isEmpty
                      ? _NoMatchingMoreOptionsState(query: filter.query)
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < visibleGroups.length;
                              index++
                            ) ...[
                              _MoreOptionGroupCard(
                                group: visibleGroups[index],
                                onOptionSelected: widget.onOptionSelected,
                              ),
                              if (index < visibleGroups.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }
}

/// Displays one category of related document tools.
class _MoreOptionGroupCard extends StatelessWidget {
  final DocumentMoreOptionGroup group;
  final ValueChanged<DocumentMoreOptionId> onOptionSelected;

  const _MoreOptionGroupCard({
    required this.group,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentPanelSectionHeader(
              icon: group.icon,
              title: group.title,
              iconSize: 18,
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            ),
            for (var index = 0; index < group.options.length; index++) ...[
              _MoreOptionTile(
                option: group.options[index],
                onPressed: group.options[index].enabled
                    ? () => onOptionSelected(group.options[index].id)
                    : null,
              ),
              if (index < group.options.length - 1)
                Divider(height: 1, color: colorScheme.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// Communicates that no document tools are currently registered.
class _EmptyMoreOptionsState extends StatelessWidget {
  const _EmptyMoreOptionsState();

  @override
  Widget build(BuildContext context) {
    return const DocumentPanelEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No document tools',
      message: 'Configured document commands will appear here.',
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
    );
  }
}

/// Communicates that a More Options search has no matching commands.
class _NoMatchingMoreOptionsState extends StatelessWidget {
  final String query;

  const _NoMatchingMoreOptionsState({required this.query});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelEmptyState(
      icon: Icons.manage_search_outlined,
      title: 'No matching tools',
      message: 'No document tools match "$query".',
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
    );
  }
}

/// Renders one tappable tool row inside the more-options sheet.
class _MoreOptionTile extends StatelessWidget {
  final DocumentMoreOption option;
  final VoidCallback? onPressed;

  const _MoreOptionTile({required this.option, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = !option.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : option.highlighted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final textColor = option.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final subtitleColor = option.enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final tile = InkWell(
      key: ValueKey('${DocumentMoreOptionsPanel.optionPrefixKey}-${option.id}'),
      borderRadius: BorderRadius.circular(7),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: option.enabled ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(option.icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (option.shortcutLabel != null) ...[
              _MoreOptionShortcutChip(
                label: option.shortcutLabel!,
                enabled: option.enabled,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              option.enabled ? Icons.chevron_right : Icons.lock_outline,
              size: 18,
              color: subtitleColor,
            ),
          ],
        ),
      ),
    );

    if (option.enabled || option.disabledReason == null) return tile;

    return Tooltip(message: option.disabledReason!, child: tile);
  }
}

/// Shows an optional keyboard shortcut for a More Options command.
class _MoreOptionShortcutChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _MoreOptionShortcutChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 88),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: enabled ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: foreground.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
