import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_health.dart';
import '../model/sheet_formula_issue_sort.dart';
import '../model/sheet_formula_issue_view_state.dart';
import '../state/sheet_formula_health_focus_provider.dart';
import '../state/sheet_formula_health_filter_provider.dart';
import '../state/sheet_formula_health_search_provider.dart';
import '../state/sheet_formula_health_sort_provider.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_formula_health_filter.dart';
import '../utils/sheet_formula_health_scanner.dart';
import '../utils/sheet_formula_issue_focus.dart';
import '../utils/sheet_formula_issue_report_builder.dart';
import '../utils/sheet_formula_issue_sorter.dart';
import '../utils/sheet_formula_issue_trace_builder.dart';
import 'sheet_formula_issue_detail_card.dart';
import 'sheet_formula_issue_code_badge.dart';
import 'sheet_formula_issue_filter_bar.dart';
import 'sheet_formula_issue_search_field.dart';
import 'sheet_formula_issue_sort_control.dart';
import 'sheet_formula_issue_view_summary.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for reviewing formula issues and tracing affected cells.
class SheetFormulaHealthPanel extends ConsumerWidget {
  const SheetFormulaHealthPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = SheetFormulaHealthScanner.scan(
      ref.watch(spreadsheetProvider),
      namedRanges: ref.watch(sheetNamedRangesProvider),
    );
    final activeIssueCode = ref.watch(
      sheetFormulaHealthIssueCodeFilterProvider,
    );
    final searchQuery = ref.watch(sheetFormulaHealthSearchQueryProvider);
    final sortMode = ref.watch(sheetFormulaHealthSortModeProvider);
    final filteredIssues = SheetFormulaHealthFilter.apply(
      health.issues,
      issueCode: activeIssueCode,
      query: searchQuery,
    );
    final visibleIssues = SheetFormulaIssueSorter.sort(
      filteredIssues,
      mode: sortMode,
    );
    final viewState = SheetFormulaIssueViewState(
      visibleIssueCount: visibleIssues.length,
      totalIssueCount: health.issueCount,
      activeCode: activeIssueCode,
      searchQuery: searchQuery,
      sortMode: sortMode,
    );

    return SheetSidebarPanelSurface(
      icon: Icons.health_and_safety_outlined,
      title: 'Formula Health',
      subtitle: 'Find formula issues',
      trailing: SheetSidebarPanelCountBadge(count: health.issueCount),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _HealthSummary(health: health),
                const SizedBox(height: 12),
                if (health.issueCountsByCode.isNotEmpty) ...[
                  SheetFormulaIssueFilterBar(
                    counts: health.issueCountsByCode,
                    activeCode: activeIssueCode,
                    onChanged: (code) {
                      ref
                              .read(
                                sheetFormulaHealthIssueCodeFilterProvider
                                    .notifier,
                              )
                              .state =
                          code;
                      ref
                              .read(
                                sheetFormulaHealthFocusedIssueIndexProvider
                                    .notifier,
                              )
                              .state =
                          0;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (health.hasIssues) ...[
                  SheetFormulaIssueSearchField(
                    value: searchQuery,
                    onChanged: (query) {
                      ref
                              .read(
                                sheetFormulaHealthSearchQueryProvider.notifier,
                              )
                              .state =
                          query;
                      ref
                              .read(
                                sheetFormulaHealthFocusedIssueIndexProvider
                                    .notifier,
                              )
                              .state =
                          0;
                    },
                  ),
                  const SizedBox(height: 12),
                  SheetFormulaIssueSortControl(
                    value: sortMode,
                    onChanged: (mode) {
                      ref
                              .read(sheetFormulaHealthSortModeProvider.notifier)
                              .state =
                          mode;
                      ref
                              .read(
                                sheetFormulaHealthFocusedIssueIndexProvider
                                    .notifier,
                              )
                              .state =
                          0;
                    },
                  ),
                  const SizedBox(height: 12),
                  SheetFormulaIssueViewSummary(
                    viewState: viewState,
                    onReset: () => _resetIssueView(ref),
                  ),
                  const SizedBox(height: 12),
                ],
                _IssueList(
                  issues: visibleIssues,
                  activeCode: activeIssueCode,
                  searchQuery: searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetIssueView(WidgetRef ref) {
    ref.read(sheetFormulaHealthIssueCodeFilterProvider.notifier).state = null;
    ref.read(sheetFormulaHealthSearchQueryProvider.notifier).state = '';
    ref.read(sheetFormulaHealthSortModeProvider.notifier).state =
        SheetFormulaIssueSortMode.cell;
    ref.read(sheetFormulaHealthFocusedIssueIndexProvider.notifier).state = 0;
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.health});

  final SheetFormulaHealth health;

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
            _HealthStat(
              label: 'Formulas',
              value: health.formulaCount.toString(),
              color: KySheetColors.text,
            ),
            const SizedBox(width: 8),
            _HealthStat(
              label: 'Healthy',
              value: health.healthyCount.toString(),
              color: KySheetColors.formula,
            ),
            const SizedBox(width: 8),
            _HealthStat(
              label: 'Issues',
              value: health.issueCount.toString(),
              color: health.hasIssues
                  ? KySheetColors.validationError
                  : KySheetColors.formula,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  const _HealthStat({
    required this.label,
    required this.value,
    required this.color,
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

class _IssueList extends ConsumerWidget {
  const _IssueList({
    required this.issues,
    required this.activeCode,
    required this.searchQuery,
  });

  final List<SheetFormulaIssue> issues;
  final String? activeCode;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedIndex = SheetFormulaIssueFocus.clampIndex(
      ref.watch(sheetFormulaHealthFocusedIssueIndexProvider),
      issues.length,
    );
    final focusedIssue = SheetFormulaIssueFocus.issueAt(issues, focusedIndex);

    if (issues.isEmpty) {
      return _EmptyHealth(
        label: activeCode != null || searchQuery.trim().isNotEmpty
            ? 'No matching formula issues'
            : 'No formula issues found',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Formula Issues',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _IssueNavigator(
          issueCount: issues.length,
          currentIndex: focusedIndex,
          onPrevious: () => _moveToIssue(ref, focusedIndex, -1),
          onNext: () => _moveToIssue(ref, focusedIndex, 1),
        ),
        const SizedBox(height: 8),
        if (focusedIssue != null) ...[
          SheetFormulaIssueDetailCard(
            issue: focusedIssue,
            onTrace: () => _traceIssue(ref, focusedIssue),
            onCopy: () => _copySelectedIssue(context, focusedIssue),
            onFocus: () => _focusIssueAt(ref, focusedIndex),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('ky-sheet-trace-visible-formula-issues'),
              onPressed: () => _traceVisibleIssues(ref),
              icon: const Icon(Icons.schema_outlined, size: 16),
              label: const Text('Trace Visible'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('ky-sheet-copy-visible-formula-issues'),
              onPressed: () => _copyVisibleIssues(context),
              icon: const Icon(Icons.content_copy, size: 16),
              label: const Text('Copy Visible'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < issues.length; index++) ...[
          _IssueTile(
            issue: issues[index],
            issueIndex: index,
            selected: index == focusedIndex,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _moveToIssue(WidgetRef ref, int focusedIndex, int delta) {
    final nextIndex = delta < 0
        ? SheetFormulaIssueFocus.previousIndex(focusedIndex, issues.length)
        : SheetFormulaIssueFocus.nextIndex(focusedIndex, issues.length);
    _focusIssueAt(ref, nextIndex);
  }

  void _focusIssueAt(WidgetRef ref, int index) {
    final issue = SheetFormulaIssueFocus.issueAt(issues, index);
    if (issue == null) return;
    final focusedIndex = SheetFormulaIssueFocus.clampIndex(
      index,
      issues.length,
    );
    ref.read(sheetFormulaHealthFocusedIssueIndexProvider.notifier).state =
        focusedIndex;
    _publishFormulaIssueTrace(ref, issue);
    ref
        .read(sheetNavigationControllerProvider)
        .goTo(CellSelection.single(issue.address), clearFormulaPreview: false);
  }

  void _traceVisibleIssues(WidgetRef ref) {
    final selections = SheetFormulaIssueTraceBuilder.buildAll(issues);
    ref.read(formulaReferencePreviewProvider.notifier).state = selections;
    ref
        .read(formulaReferencePreviewContextProvider.notifier)
        .state = selections.isEmpty
        ? null
        : SheetFormulaPreviewContext(
            source: SheetFormulaPreviewSource.formulaIssues,
            originLabel: activeCode ?? 'Visible issues',
            targetCount: selections.length,
          );
  }

  void _traceIssue(WidgetRef ref, SheetFormulaIssue issue) {
    _publishFormulaIssueTrace(ref, issue);
  }

  Future<void> _copySelectedIssue(
    BuildContext context,
    SheetFormulaIssue issue,
  ) async {
    await _copyIssueReport(
      context,
      text: SheetFormulaIssueReportBuilder.buildTsv([issue]),
      message: 'Copied ${issue.label} formula issue',
    );
  }

  Future<void> _copyVisibleIssues(BuildContext context) async {
    await _copyIssueReport(
      context,
      text: SheetFormulaIssueReportBuilder.buildTsv(issues),
      message:
          'Copied ${issues.length} visible formula ${issues.length == 1 ? 'issue' : 'issues'}',
    );
  }

  Future<void> _copyIssueReport(
    BuildContext context, {
    required String text,
    required String message,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }
}

class _IssueNavigator extends StatelessWidget {
  const _IssueNavigator({
    required this.issueCount,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final int issueCount;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('ky-sheet-formula-health-previous-issue'),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              tooltip: 'Previous Formula Issue',
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                'Issue ${currentIndex + 1} of $issueCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('ky-sheet-formula-health-next-issue'),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              tooltip: 'Next Formula Issue',
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends ConsumerWidget {
  const _IssueTile({
    required this.issue,
    required this.issueIndex,
    required this.selected,
  });

  final SheetFormulaIssue issue;
  final int issueIndex;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      key: ValueKey('ky-sheet-formula-issue-tile-${issue.label}'),
      color: selected ? KySheetColors.accentSoft : KySheetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? KySheetColors.accent : KySheetColors.gridLine,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _focusIssue(ref),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: KySheetColors.validationError,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          issue.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: SheetFormulaIssueCodeBadge(code: issue.code),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      issue.suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    key: ValueKey(
                      'ky-sheet-trace-formula-issue-${issue.label}',
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: 'Trace Formula Issue',
                    onPressed: () => _traceIssue(ref),
                    icon: const Icon(Icons.schema_outlined),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: KySheetColors.mutedText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _traceIssue(WidgetRef ref) {
    ref.read(sheetFormulaHealthFocusedIssueIndexProvider.notifier).state =
        issueIndex;
    _publishFormulaIssueTrace(ref, issue);
  }

  void _focusIssue(WidgetRef ref) {
    ref.read(sheetFormulaHealthFocusedIssueIndexProvider.notifier).state =
        issueIndex;
    _publishFormulaIssueTrace(ref, issue);
    ref
        .read(sheetNavigationControllerProvider)
        .goTo(CellSelection.single(issue.address), clearFormulaPreview: false);
  }
}

void _publishFormulaIssueTrace(WidgetRef ref, SheetFormulaIssue issue) {
  final selections = SheetFormulaIssueTraceBuilder.build(issue);
  ref.read(formulaReferencePreviewProvider.notifier).state = selections;
  ref
      .read(formulaReferencePreviewContextProvider.notifier)
      .state = selections.isEmpty
      ? null
      : SheetFormulaPreviewContext(
          source: SheetFormulaPreviewSource.formulaIssue,
          originLabel: issue.label,
          targetCount: selections.length,
        );
}

class _EmptyHealth extends StatelessWidget {
  const _EmptyHealth({required this.label});

  final String label;

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
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: KySheetColors.formula,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
