import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_go_to_special.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_go_to_special_scanner.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for finding cells by type and jumping to matching addresses.
class SheetGoToSpecialPanel extends ConsumerStatefulWidget {
  const SheetGoToSpecialPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<SheetGoToSpecialPanel> createState() =>
      _SheetGoToSpecialPanelState();
}

/// State holder for the selected Go To Special match kind.
class _SheetGoToSpecialPanelState extends ConsumerState<SheetGoToSpecialPanel> {
  SheetGoToSpecialKind _kind = SheetGoToSpecialKind.formulas;

  @override
  Widget build(BuildContext context) {
    final result = SheetGoToSpecialScanner.scan(
      kind: _kind,
      cells: ref.watch(spreadsheetProvider),
    );

    return SheetSidebarPanelSurface(
      icon: Icons.manage_search,
      title: 'Go To Special',
      subtitle: 'Find cells by type',
      trailing: SheetSidebarPanelCountBadge(count: result.totalCount),
      onClose: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DropdownButtonFormField<SheetGoToSpecialKind>(
            key: const ValueKey('ky-sheet-go-to-special-kind'),
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Find',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final kind in SheetGoToSpecialKind.values)
                DropdownMenuItem(value: kind, child: Text(kind.label)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _kind = value);
            },
          ),
          const SizedBox(height: 12),
          _ResultSummary(result: result),
          const SizedBox(height: 12),
          _MatchList(result: result),
        ],
      ),
    );
  }
}

/// Summary card for the current Go To Special result set.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});

  final SheetGoToSpecialResult result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _SummaryStat(label: 'Matches', value: result.totalCount.toString()),
            const SizedBox(width: 10),
            _SummaryStat(label: 'Range', value: result.usedRangeLabel),
          ],
        ),
      ),
    );
  }
}

/// Compact label and value pair used by Go To Special summaries.
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// Result list that renders matching cells for the active kind.
class _MatchList extends StatelessWidget {
  const _MatchList({required this.result});

  final SheetGoToSpecialResult result;

  @override
  Widget build(BuildContext context) {
    if (result.matches.isEmpty) {
      return _EmptyMatches(kind: result.kind);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.isTruncated) ...[
          _TruncatedNotice(
            shown: result.matches.length,
            total: result.totalCount,
          ),
          const SizedBox(height: 8),
        ],
        for (final match in result.matches) ...[
          _MatchTile(match: match, kind: result.kind),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Clickable result row that moves the active cell to a match.
class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match, required this.kind});

  final SheetGoToSpecialMatch match;
  final SheetGoToSpecialKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: KySheetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: KySheetColors.gridLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref
            .read(sheetNavigationControllerProvider)
            .goTo(CellSelection.single(match.address)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(_iconFor(kind), size: 18, color: KySheetColors.accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      match.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new,
                size: 16,
                color: KySheetColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SheetGoToSpecialKind kind) {
    return switch (kind) {
      SheetGoToSpecialKind.formulas => Icons.functions,
      SheetGoToSpecialKind.constants => Icons.text_fields,
      SheetGoToSpecialKind.blanks => Icons.crop_free,
      SheetGoToSpecialKind.formulaErrors => Icons.error_outline,
      SheetGoToSpecialKind.comments => Icons.comment_outlined,
      SheetGoToSpecialKind.hyperlinks => Icons.link,
      SheetGoToSpecialKind.validations => Icons.rule,
    };
  }
}

/// Inline notice shown when only a subset of matches is rendered.
class _TruncatedNotice extends StatelessWidget {
  const _TruncatedNotice({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        border: Border.all(color: KySheetColors.headerActive),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Text(
          'Showing $shown of $total matches',
          style: const TextStyle(
            color: KySheetColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Empty state for a Go To Special category with no matches.
class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches({required this.kind});

  final SheetGoToSpecialKind kind;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'No ${kind.label.toLowerCase()} found',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
