import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/workbook_sheet.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_hidden_sheet_row.dart';
import 'workbook_sheet_menu_item.dart';

/// Action returned when the sheet navigator closes with a sheet operation.
enum SheetNavigatorDialogAction { select, unhideAndSelect }

/// Result from the sheet navigator dialog.
class SheetNavigatorDialogResult {
  const SheetNavigatorDialogResult._({
    required this.sheetId,
    required this.action,
  });

  /// Creates a result for selecting a visible sheet.
  const SheetNavigatorDialogResult.select(String sheetId)
    : this._(sheetId: sheetId, action: SheetNavigatorDialogAction.select);

  /// Creates a result for restoring a hidden sheet and switching to it.
  const SheetNavigatorDialogResult.unhideAndSelect(String sheetId)
    : this._(
        sheetId: sheetId,
        action: SheetNavigatorDialogAction.unhideAndSelect,
      );

  /// Target workbook sheet id.
  final String sheetId;

  /// Operation chosen from the navigator.
  final SheetNavigatorDialogAction action;
}

/// Searchable dialog for jumping between workbook sheets.
class SheetNavigatorDialog extends StatefulWidget {
  const SheetNavigatorDialog({
    super.key,
    required this.sheets,
    required this.activeSheetId,
    this.recentSheetIds = const [],
  });

  /// Workbook sheets available for navigation.
  final List<WorkbookSheet> sheets;

  /// Currently active workbook sheet id.
  final String activeSheetId;

  /// Recently visited workbook sheet ids in newest-first order.
  final List<String> recentSheetIds;

  @override
  State<SheetNavigatorDialog> createState() => _SheetNavigatorDialogState();
}

/// Manages sheet search text and filtered navigator results.
class _SheetNavigatorDialogState extends State<SheetNavigatorDialog> {
  final _searchController = TextEditingController();
  final _resultsController = ScrollController();
  String _query = '';
  int _highlightedIndex = 0;
  String? _lastVisibleHighlightedSheetId;

  @override
  void initState() {
    super.initState();
    final visibleSheets = [
      for (final sheet in widget.sheets)
        if (!sheet.hidden) sheet,
    ];
    final activeIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == widget.activeSheetId,
    );
    if (activeIndex != -1) {
      _highlightedIndex = activeIndex;
    }
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults = _filteredVisibleSheets;
    final recentResults = _recentVisibleSheets(visibleResults);
    final visibleSections = _visibleSections(
      visibleResults: visibleResults,
      recentResults: recentResults,
    );
    final selectableResults = _selectableResults(visibleSections);
    final hiddenResults = _filteredHiddenSheets;
    final highlightedIndex = _clampedHighlightedIndex(selectableResults.length);
    _scheduleHighlightedResultVisibility(selectableResults);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1, selectableResults),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1, selectableResults),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _selectHighlighted(selectableResults),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.table_chart_outlined,
                      size: 20,
                      color: KySheetColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All Sheets',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: KySheetColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _SheetNavigatorCountBadge(
                      visibleCount: widget.sheets
                          .where((sheet) => !sheet.hidden)
                          .length,
                      hiddenCount: widget.sheets
                          .where((sheet) => sheet.hidden)
                          .length,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('ky-sheet-navigator-search'),
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search sheets',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('ky-sheet-navigator-clear'),
                            tooltip: 'Clear search',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _selectHighlighted(selectableResults),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: selectableResults.isEmpty && hiddenResults.isEmpty
                      ? const _SheetNavigatorEmptyState()
                      : ListView(
                          key: const ValueKey('ky-sheet-navigator-results'),
                          controller: _resultsController,
                          shrinkWrap: true,
                          children: [
                            ..._visibleResultWidgets(
                              sections: visibleSections,
                              highlightedIndex: highlightedIndex,
                            ),
                            if (hiddenResults.isNotEmpty) ...[
                              if (selectableResults.isNotEmpty)
                                const Divider(height: 12),
                              _SheetNavigatorSectionHeader(
                                label: 'Hidden',
                                count: hiddenResults.length,
                                icon: Icons.visibility_off_outlined,
                              ),
                              for (final result in hiddenResults)
                                SheetHiddenSheetRow(
                                  key: ValueKey(
                                    'ky-sheet-hidden-${result.sheet.id}',
                                  ),
                                  sheet: result.sheet,
                                  position: result.position,
                                  onUnhide: () => Navigator.of(context).pop(
                                    SheetNavigatorDialogResult.unhideAndSelect(
                                      result.sheet.id,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_SheetNavigatorEntry> get _filteredVisibleSheets {
    return _filteredSheets(hidden: false);
  }

  List<_SheetNavigatorEntry> get _filteredHiddenSheets {
    return _filteredSheets(hidden: true);
  }

  List<_SheetNavigatorEntry> _recentVisibleSheets(
    List<_SheetNavigatorEntry> visibleResults,
  ) {
    if (_query.trim().isNotEmpty || widget.recentSheetIds.isEmpty) {
      return const [];
    }

    final visibleResultsById = {
      for (final result in visibleResults) result.sheet.id: result,
    };

    return [
      for (final sheetId in widget.recentSheetIds)
        if (sheetId != widget.activeSheetId &&
            visibleResultsById[sheetId] != null)
          visibleResultsById[sheetId]!,
    ];
  }

  List<_SheetNavigatorSection> _visibleSections({
    required List<_SheetNavigatorEntry> visibleResults,
    required List<_SheetNavigatorEntry> recentResults,
  }) {
    if (recentResults.isEmpty) {
      return [
        if (visibleResults.isNotEmpty)
          _SheetNavigatorSection(entries: visibleResults),
      ];
    }

    final recentSheetIds = {
      for (final result in recentResults) result.sheet.id,
    };
    final allResults = [
      for (final result in visibleResults)
        if (!recentSheetIds.contains(result.sheet.id)) result,
    ];

    return [
      _SheetNavigatorSection(
        label: 'Recent',
        icon: Icons.history,
        entries: recentResults,
      ),
      if (allResults.isNotEmpty)
        _SheetNavigatorSection(
          label: 'All',
          icon: Icons.table_chart_outlined,
          entries: allResults,
        ),
    ];
  }

  List<_SheetNavigatorEntry> _selectableResults(
    List<_SheetNavigatorSection> sections,
  ) {
    return [
      for (final section in sections)
        for (final entry in section.entries) entry,
    ];
  }

  List<Widget> _visibleResultWidgets({
    required List<_SheetNavigatorSection> sections,
    required int highlightedIndex,
  }) {
    var resultIndex = 0;
    final widgets = <Widget>[];

    for (final section in sections) {
      final label = section.label;
      if (label != null) {
        if (widgets.isNotEmpty) {
          widgets.add(const Divider(height: 12));
        }
        widgets.add(
          _SheetNavigatorSectionHeader(
            label: label,
            count: section.entries.length,
            icon: section.icon,
          ),
        );
      }

      for (final entry in section.entries.indexed) {
        final navigatorEntry = entry.$2;
        widgets.add(
          _SheetNavigatorResultTile(
            key: ValueKey('ky-sheet-tabs-navigator-${navigatorEntry.sheet.id}'),
            entry: navigatorEntry,
            active: navigatorEntry.sheet.id == widget.activeSheetId,
            highlighted: resultIndex == highlightedIndex,
            onTap: () => Navigator.of(
              context,
            ).pop(SheetNavigatorDialogResult.select(navigatorEntry.sheet.id)),
          ),
        );
        resultIndex += 1;

        if (entry.$1 < section.entries.length - 1) {
          widgets.add(const Divider(height: 1));
        }
      }
    }

    return widgets;
  }

  List<_SheetNavigatorEntry> _filteredSheets({required bool hidden}) {
    final query = _SheetNavigatorQuery(_query);
    return [
      for (final entry in widget.sheets.indexed)
        if (entry.$2.hidden == hidden &&
            query.matches(position: entry.$1, sheet: entry.$2))
          _SheetNavigatorEntry(position: entry.$1, sheet: entry.$2),
    ];
  }

  void _handleSearchChanged() {
    setState(() {
      _query = _searchController.text;
      _highlightedIndex = 0;
      _lastVisibleHighlightedSheetId = null;
    });
  }

  void _moveHighlight(int delta, List<_SheetNavigatorEntry> results) {
    if (results.isEmpty) return;

    setState(() {
      _highlightedIndex =
          (_clampedHighlightedIndex(results.length) + delta) % results.length;
      if (_highlightedIndex < 0) {
        _highlightedIndex += results.length;
      }
    });
  }

  void _selectHighlighted(List<_SheetNavigatorEntry> results) {
    if (results.isEmpty) return;
    Navigator.of(context).pop(
      SheetNavigatorDialogResult.select(
        results[_clampedHighlightedIndex(results.length)].sheet.id,
      ),
    );
  }

  int _clampedHighlightedIndex(int length) {
    if (length == 0 || _highlightedIndex < 0) return 0;
    if (_highlightedIndex >= length) return length - 1;
    return _highlightedIndex;
  }

  void _scheduleHighlightedResultVisibility(
    List<_SheetNavigatorEntry> results,
  ) {
    if (results.isEmpty) {
      _lastVisibleHighlightedSheetId = null;
      return;
    }

    final highlightedSheetId =
        results[_clampedHighlightedIndex(results.length)].sheet.id;
    if (_lastVisibleHighlightedSheetId == highlightedSheetId) return;
    _lastVisibleHighlightedSheetId = highlightedSheetId;
    final highlightedIndex = _clampedHighlightedIndex(results.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_resultsController.hasClients) return;

      final position = _resultsController.position;
      final resultStride = _SheetNavigatorResultTile.rowExtent + 1;
      final rowTop = highlightedIndex * resultStride;
      final rowBottom = rowTop + _SheetNavigatorResultTile.rowExtent;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      var target = viewportTop;

      if (rowTop < viewportTop) {
        target = rowTop;
      } else if (rowBottom > viewportBottom) {
        target = rowBottom - position.viewportDimension;
      }

      target = target
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();

      if ((target - position.pixels).abs() < 0.5) return;

      _resultsController.animateTo(
        target,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

/// Compact count summary for visible and hidden navigator sheets.
class _SheetNavigatorCountBadge extends StatelessWidget {
  const _SheetNavigatorCountBadge({
    required this.visibleCount,
    required this.hiddenCount,
  });

  final int visibleCount;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    if (hiddenCount == 0) {
      return Text(
        '$visibleCount',
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$visibleCount',
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: KySheetColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: KySheetColors.gridLineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                size: 12,
                color: KySheetColors.mutedText,
              ),
              const SizedBox(width: 3),
              Text(
                '$hiddenCount',
                style: const TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section label used to separate hidden sheets from visible navigator results.
class _SheetNavigatorSectionHeader extends StatelessWidget {
  const _SheetNavigatorSectionHeader({
    required this.label,
    required this.count,
    this.icon,
  });

  final String label;
  final int count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: KySheetColors.mutedText),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtered sheet result with its original workbook position.
class _SheetNavigatorEntry {
  const _SheetNavigatorEntry({required this.position, required this.sheet});

  final int position;
  final WorkbookSheet sheet;
}

/// Visible navigator section with optional header metadata.
class _SheetNavigatorSection {
  const _SheetNavigatorSection({this.label, this.icon, required this.entries});

  final String? label;
  final IconData? icon;
  final List<_SheetNavigatorEntry> entries;
}

/// Normalized matcher for sheet navigator name and position search.
class _SheetNavigatorQuery {
  const _SheetNavigatorQuery(this.raw);

  final String raw;

  String get normalized => raw.trim().toLowerCase();

  bool get isEmpty => normalized.isEmpty;

  bool matches({required int position, required WorkbookSheet sheet}) {
    if (isEmpty) return true;

    final positionLabel = '${position + 1}';
    return sheet.name.toLowerCase().contains(normalized) ||
        _normalizedPositionQuery == positionLabel;
  }

  String get _normalizedPositionQuery {
    if (normalized.startsWith('#')) {
      return normalized.substring(1).trim();
    }

    for (final prefix in const ['sheet', 'tab', 's']) {
      if (normalized.startsWith(prefix)) {
        return normalized.substring(prefix.length).trim();
      }
    }

    return normalized;
  }
}

/// Interactive result row in the searchable sheet navigator.
class _SheetNavigatorResultTile extends StatelessWidget {
  const _SheetNavigatorResultTile({
    super.key,
    required this.entry,
    required this.active,
    required this.highlighted,
    required this.onTap,
  });

  static const rowExtent = 44.0;

  final _SheetNavigatorEntry entry;
  final bool active;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return Semantics(
      button: true,
      selected: highlighted,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted ? KySheetColors.accentSoft : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: highlighted ? KySheetColors.accent : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: rowExtent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: WorkbookSheetMenuItem(
                  name: entry.sheet.name,
                  active: active,
                  indexLabel: '${entry.position + 1}',
                  tabColor: entry.sheet.tabColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state for sheet navigator searches without matches.
class _SheetNavigatorEmptyState extends StatelessWidget {
  const _SheetNavigatorEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No sheets found',
          style: TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
