import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_review_item.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_review_scanner.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for reviewing comments and hyperlinks in the active sheet.
class SheetReviewPanel extends ConsumerStatefulWidget {
  const SheetReviewPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<SheetReviewPanel> createState() => _SheetReviewPanelState();
}

/// State holder for review item filtering.
class _SheetReviewPanelState extends ConsumerState<SheetReviewPanel> {
  SheetReviewItemKind? _filterKind;

  @override
  Widget build(BuildContext context) {
    final summary = SheetReviewScanner.scan(ref.watch(spreadsheetProvider));
    final visibleItems = [
      for (final item in summary.items)
        if (_filterKind == null || item.kind == _filterKind) item,
    ];

    return SheetSidebarPanelSurface(
      icon: Icons.rate_review_outlined,
      title: 'Review',
      subtitle: 'Comments and links',
      trailing: SheetSidebarPanelCountBadge(count: summary.totalCount),
      onClose: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _ReviewSummary(summary: summary),
          const SizedBox(height: 12),
          _ReviewFilter(
            value: _filterKind,
            onChanged: (value) => setState(() => _filterKind = value),
          ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            _EmptyReview(filterKind: _filterKind)
          else
            for (final item in visibleItems) ...[
              _ReviewTile(item: item),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Summary card for review item totals.
class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.summary});

  final SheetReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _ReviewStat(label: 'Total', value: summary.totalCount.toString()),
            const SizedBox(width: 8),
            _ReviewStat(
              label: 'Comments',
              value: summary.commentCount.toString(),
              color: KySheetColors.comment,
            ),
            const SizedBox(width: 8),
            _ReviewStat(
              label: 'Links',
              value: summary.hyperlinkCount.toString(),
              color: KySheetColors.formula,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact metric used by the review summary card.
class _ReviewStat extends StatelessWidget {
  const _ReviewStat({
    required this.label,
    required this.value,
    this.color = KySheetColors.text,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown filter for choosing all review items, comments, or hyperlinks.
class _ReviewFilter extends StatelessWidget {
  const _ReviewFilter({required this.value, required this.onChanged});

  final SheetReviewItemKind? value;
  final ValueChanged<SheetReviewItemKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SheetReviewItemKind?>(
      key: const ValueKey('ky-sheet-review-filter'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Show',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All review items')),
        for (final kind in SheetReviewItemKind.values)
          DropdownMenuItem(value: kind, child: Text(kind.pluralLabel)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Review item row that can navigate, open inspector, or clear metadata.
class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.item});

  final SheetReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComment = item.kind == SheetReviewItemKind.comment;

    return Material(
      color: KySheetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: KySheetColors.gridLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _goToItem(ref),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewBadge(kind: item.kind),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.address.label,
                          style: const TextStyle(
                            color: KySheetColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.kind.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: KySheetColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Open Inspector',
                    icon: const Icon(Icons.info_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _goToItem(ref);
                      ref.read(activeSidebarPanelProvider.notifier).state =
                          SheetSidebarPanel.cellInspector;
                    },
                  ),
                  IconButton(
                    tooltip: isComment ? 'Clear Comment' : 'Clear Hyperlink',
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _clearItem(ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToItem(WidgetRef ref) {
    ref
        .read(sheetNavigationControllerProvider)
        .goTo(CellSelection.single(item.address));
  }

  void _clearItem(WidgetRef ref) {
    final data = ref.read(spreadsheetProvider);
    final current = data[item.address];
    if (current == null) return;

    ref
        .read(spreadsheetProvider.notifier)
        .updateCell(
          item.address,
          item.kind == SheetReviewItemKind.comment
              ? current.copyWith(clearComment: true)
              : current.copyWith(clearHyperlink: true),
        );
  }
}

/// Icon badge for the review item kind.
class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge({required this.kind});

  final SheetReviewItemKind kind;

  @override
  Widget build(BuildContext context) {
    final isComment = kind == SheetReviewItemKind.comment;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isComment ? const Color(0xFFFFFBEB) : KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComment ? KySheetColors.comment : KySheetColors.headerActive,
        ),
      ),
      child: Icon(
        isComment ? Icons.comment_outlined : Icons.link,
        size: 17,
        color: isComment ? KySheetColors.comment : KySheetColors.accent,
      ),
    );
  }
}

/// Empty state for the current review filter.
class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.filterKind});

  final SheetReviewItemKind? filterKind;

  @override
  Widget build(BuildContext context) {
    final label = filterKind == null
        ? 'No comments or hyperlinks yet'
        : 'No ${filterKind!.pluralLabel.toLowerCase()} yet';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
