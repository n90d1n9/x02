import 'sheet_formula_issue_code_info.dart';
import 'sheet_formula_issue_sort.dart';

class SheetFormulaIssueViewState {
  const SheetFormulaIssueViewState({
    required this.visibleIssueCount,
    required this.totalIssueCount,
    this.activeCode,
    this.searchQuery = '',
    this.sortMode = SheetFormulaIssueSortMode.cell,
  });

  final int visibleIssueCount;
  final int totalIssueCount;
  final String? activeCode;
  final String searchQuery;
  final SheetFormulaIssueSortMode sortMode;

  bool get hasCodeFilter => activeCode?.trim().isNotEmpty ?? false;
  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;
  bool get hasCustomSort => sortMode != SheetFormulaIssueSortMode.cell;

  bool get canReset => hasCodeFilter || hasSearchQuery || hasCustomSort;

  String get countLabel {
    if (visibleIssueCount == totalIssueCount) {
      return 'Showing $totalIssueCount ${_issueNoun(totalIssueCount)}';
    }
    return 'Showing $visibleIssueCount of $totalIssueCount ${_issueNoun(totalIssueCount)}';
  }

  List<String> get activeBadges => [
    if (hasCodeFilter)
      'Type: ${SheetFormulaIssueCodeCatalog.describe(activeCode!).compactLabel}',
    if (hasSearchQuery) 'Search: ${searchQuery.trim()}',
    if (hasCustomSort) 'Sort: ${sortMode.label}',
  ];

  static String _issueNoun(int count) => count == 1 ? 'issue' : 'issues';
}
