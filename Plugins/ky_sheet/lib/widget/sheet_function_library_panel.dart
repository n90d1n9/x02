import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_formula_function.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for browsing and inserting supported spreadsheet functions.
class SheetFunctionLibraryPanel extends ConsumerStatefulWidget {
  const SheetFunctionLibraryPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<SheetFunctionLibraryPanel> createState() =>
      _SheetFunctionLibraryPanelState();
}

class _SheetFunctionLibraryPanelState
    extends ConsumerState<SheetFunctionLibraryPanel> {
  final _searchController = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final query = _searchController.text;
    final functions = _filteredFunctions(query: query, category: _category);
    final categories = _categories();

    return SheetSidebarPanelSurface(
      icon: Icons.functions,
      title: 'Function Library',
      subtitle: 'Browse formulas',
      trailing: SheetSidebarPanelLabelBadge(
        label: selection?.start.label ?? 'None',
      ),
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _LibrarySummary(
                  totalCount: SheetFormulaCatalog.functions.length,
                  visibleCount: functions.length,
                  categoryCount: categories.length,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('ky-sheet-function-search'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search functions',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  key: const ValueKey('ky-sheet-function-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final category in categories)
                      DropdownMenuItem(
                        key: ValueKey('ky-sheet-function-category-$category'),
                        value: category,
                        child: Text(category),
                      ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 14),
                if (functions.isEmpty)
                  const _EmptyFunctions()
                else
                  for (final function in functions) ...[
                    _FunctionTile(
                      function: function,
                      canInsert: selection != null,
                      onInsert: selection == null
                          ? null
                          : () {
                              ref
                                  .read(toolbarControllerProvider)
                                  .insertFunction(
                                    selection.start,
                                    function.name,
                                  );
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SheetFormulaFunction> _filteredFunctions({
    required String query,
    required String? category,
  }) {
    final matches = [
      for (final function in SheetFormulaCatalog.functions)
        if ((category == null || function.category == category) &&
            function.matches(query))
          function,
    ];

    matches.sort((left, right) {
      final rank = left.rankFor(query).compareTo(right.rankFor(query));
      if (rank != 0) return rank;
      final categoryCompare = left.category.compareTo(right.category);
      if (categoryCompare != 0) return categoryCompare;
      return left.name.compareTo(right.name);
    });

    return matches;
  }

  List<String> _categories() {
    return SheetFormulaCatalog.functions
        .map((function) => function.category)
        .toSet()
        .toList()
      ..sort();
  }
}

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({
    required this.totalCount,
    required this.visibleCount,
    required this.categoryCount,
  });

  final int totalCount;
  final int visibleCount;
  final int categoryCount;

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
            _LibraryStat(label: 'Functions', value: totalCount.toString()),
            const SizedBox(width: 8),
            _LibraryStat(label: 'Shown', value: visibleCount.toString()),
            const SizedBox(width: 8),
            _LibraryStat(label: 'Groups', value: categoryCount.toString()),
          ],
        ),
      ),
    );
  }
}

class _LibraryStat extends StatelessWidget {
  const _LibraryStat({required this.label, required this.value});

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
            style: const TextStyle(
              color: KySheetColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FunctionTile extends StatelessWidget {
  const _FunctionTile({
    required this.function,
    required this.canInsert,
    required this.onInsert,
  });

  final SheetFormulaFunction function;
  final bool canInsert;
  final VoidCallback? onInsert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KySheetColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KySheetColors.headerActive),
            ),
            child: const Icon(
              Icons.functions,
              size: 17,
              color: KySheetColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      function.name,
                      style: const TextStyle(
                        color: KySheetColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        function.category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KySheetColors.formula,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  function.signature,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  function.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            key: ValueKey('ky-sheet-function-insert-${function.name}'),
            tooltip: canInsert ? 'Insert ${function.name}' : 'Select a cell',
            onPressed: onInsert,
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyFunctions extends StatelessWidget {
  const _EmptyFunctions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: const Text(
        'No functions found',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
