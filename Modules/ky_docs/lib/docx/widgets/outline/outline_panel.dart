import 'package:flutter/material.dart';

import '../../models/document_outline.dart';
import '../navigation/document_navigation_panel_switcher.dart';
import '../navigation/document_navigation_rail_header.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_filter_bar.dart';
import '../panel/document_panel_search_field.dart';
import 'document_outline_navigation_model.dart';

/// Provides a searchable document map for jumping between document headings.
class DocxOutlinePanel extends StatefulWidget {
  static const searchFieldKey = Key('docx-outline-search-field');
  static const pagesButtonKey = Key('docx-outline-pages-button');
  static const closeButtonKey = Key('docx-outline-close-button');
  static const filterPrefixKey = 'docx-outline-filter';
  static const tilePrefixKey = 'docx-outline-tile';

  final List<DocumentOutline> outline;
  final ValueChanged<int> onJumpToOffset;
  final VoidCallback? onOpenPageNavigator;
  final VoidCallback? onClose;

  const DocxOutlinePanel({
    super.key,
    required this.outline,
    required this.onJumpToOffset,
    this.onOpenPageNavigator,
    this.onClose,
  });

  @override
  State<DocxOutlinePanel> createState() => _DocxOutlinePanelState();
}

class _DocxOutlinePanelState extends State<DocxOutlinePanel> {
  final _searchController = TextEditingController();
  var _levelFilter = DocumentOutlineLevelFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final model = DocumentOutlineNavigationModel(
      source: widget.outline,
      query: _searchController.text,
      levelFilter: _levelFilter,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentNavigationRailHeader(
            icon: Icons.account_tree_outlined,
            title: 'Document map',
            subtitle: 'Jump between headings',
            countLabel: _outlineCountLabel(model),
            closeButtonKey: DocxOutlinePanel.closeButtonKey,
            onClose: widget.onClose,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DocumentNavigationPanelSwitcher(
              selectedMode: DocumentNavigationPanelMode.outline,
              onPagesSelected: widget.onOpenPageNavigator,
              pagesButtonKey: DocxOutlinePanel.pagesButtonKey,
            ),
          ),
          DocumentPanelSearchField(
            fieldKey: DocxOutlinePanel.searchFieldKey,
            controller: _searchController,
            hintText: 'Search headings',
            onChanged: (_) => setState(() {}),
            onClear: _clearSearch,
            clearTooltip: 'Clear outline search',
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            borderRadius: 10,
          ),
          _OutlineLevelFilters(
            selectedFilter: _levelFilter,
            counts: model.levelCounts,
            onSelected: (filter) => setState(() => _levelFilter = filter),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _OutlineContent(
              model: model,
              onJumpToOffset: widget.onJumpToOffset,
            ),
          ),
        ],
      ),
    );
  }

  String _outlineCountLabel(DocumentOutlineNavigationModel model) {
    if (model.hasQuery || model.levelFilter != DocumentOutlineLevelFilter.all) {
      return '${model.visibleCount}/${model.totalCount}';
    }
    return model.totalCount.toString();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }
}

class _OutlineLevelFilters extends StatelessWidget {
  final DocumentOutlineLevelFilter selectedFilter;
  final Map<DocumentOutlineLevelFilter, int> counts;
  final ValueChanged<DocumentOutlineLevelFilter> onSelected;

  const _OutlineLevelFilters({
    required this.selectedFilter,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelFilterBar<DocumentOutlineLevelFilter>(
      keyPrefix: DocxOutlinePanel.filterPrefixKey,
      selectedValue: selectedFilter,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      spacing: 6,
      options: [
        for (final filter in DocumentOutlineLevelFilter.values)
          DocumentPanelFilterOption(
            value: filter,
            keySuffix: filter.name,
            label: filter.label,
            count: counts[filter] ?? 0,
            tooltip: filter.description,
          ),
      ],
      onSelected: onSelected,
    );
  }
}

class _OutlineContent extends StatelessWidget {
  final DocumentOutlineNavigationModel model;
  final ValueChanged<int> onJumpToOffset;

  const _OutlineContent({required this.model, required this.onJumpToOffset});

  @override
  Widget build(BuildContext context) {
    if (model.totalCount == 0) {
      return const DocumentPanelEmptyState(
        icon: Icons.subject_outlined,
        title: 'No headings found',
        message: 'Use heading styles or markdown # headings to build a map.',
        tone: DocumentPanelEmptyStateTone.centered,
      );
    }

    final visibleOutline = model.visibleOutline;
    if (visibleOutline.isEmpty) {
      return const DocumentPanelEmptyState(
        icon: Icons.manage_search_outlined,
        title: 'No matching headings',
        message: 'Try a different search or heading level filter.',
        tone: DocumentPanelEmptyStateTone.centered,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: visibleOutline.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final item = visibleOutline[index];
        return _OutlineTile(
          key: Key('${DocxOutlinePanel.tilePrefixKey}-${item.id}'),
          item: item,
          onTap: () => onJumpToOffset(item.offset),
        );
      },
    );
  }
}

class _OutlineTile extends StatelessWidget {
  final DocumentOutline item;
  final VoidCallback onTap;

  const _OutlineTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedLevel = item.level.clamp(1, 6);
    final isPrimaryHeading = normalizedLevel == 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            6 + ((normalizedLevel - 1) * 12.0),
            5,
            6,
            5,
          ),
          child: Row(
            children: [
              _HeadingLevelBadge(level: normalizedLevel),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: isPrimaryHeading
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isPrimaryHeading) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Section start',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadingLevelBadge extends StatelessWidget {
  final int level;

  const _HeadingLevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPrimaryHeading = level == 1;

    return Container(
      width: 28,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPrimaryHeading
            ? colorScheme.primaryContainer.withValues(alpha: 0.78)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimaryHeading
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        'H$level',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isPrimaryHeading
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
