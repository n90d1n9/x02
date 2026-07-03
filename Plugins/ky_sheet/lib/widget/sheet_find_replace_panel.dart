import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_search_match.dart';
import '../state/sheet_find_replace_provider.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for finding and replacing cell values or formulas.
class SheetFindReplacePanel extends ConsumerStatefulWidget {
  const SheetFindReplacePanel({super.key, this.onClose});

  /// Called when the user closes the sidebar panel.
  final VoidCallback? onClose;

  @override
  ConsumerState<SheetFindReplacePanel> createState() =>
      _SheetFindReplacePanelState();
}

/// State holder for find and replace input controllers.
class _SheetFindReplacePanelState extends ConsumerState<SheetFindReplacePanel> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _findFocusNode = FocusNode();
  final _replaceFocusNode = FocusNode();

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    _replaceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(findReplaceQueryProvider);
    final replacement = ref.watch(findReplaceReplacementProvider);
    final matchCase = ref.watch(findReplaceMatchCaseProvider);
    final scope = ref.watch(findReplaceScopeProvider);
    final options = ref.watch(findReplaceOptionsProvider);
    final matches = ref.watch(findReplaceMatchesProvider);
    final currentIndex = ref.watch(findReplaceCurrentIndexProvider);
    final focusTarget = ref.watch(findReplaceFocusTargetProvider);
    final safeIndex = matches.isEmpty
        ? 0
        : currentIndex.clamp(0, matches.length - 1).toInt();

    if (focusTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (focusTarget) {
          case SheetFindReplaceFocusTarget.find:
            _findFocusNode.requestFocus();
          case SheetFindReplaceFocusTarget.replace:
            _replaceFocusNode.requestFocus();
        }
        ref.read(findReplaceFocusTargetProvider.notifier).state = null;
      });
    }
    if (safeIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(findReplaceCurrentIndexProvider.notifier).state = safeIndex;
      });
    }
    if (!_findFocusNode.hasFocus && _findController.text != query) {
      _syncController(_findController, query);
    }
    if (!_replaceFocusNode.hasFocus && _replaceController.text != replacement) {
      _syncController(_replaceController, replacement);
    }

    return SheetSidebarPanelSurface(
      icon: Icons.find_replace,
      title: 'Find & Replace',
      subtitle: 'Search and replace',
      trailing: SheetSidebarPanelLabelBadge(
        label: _matchCounter(matches.length, safeIndex),
      ),
      onClose: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            key: const ValueKey('ky-sheet-find-input'),
            controller: _findController,
            focusNode: _findFocusNode,
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Find',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(findReplaceQueryProvider.notifier).state = value;
              ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
            },
            onSubmitted: (_) => _selectMatch(matches, safeIndex),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('ky-sheet-replace-input'),
            controller: _replaceController,
            focusNode: _replaceFocusNode,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Replace',
              prefixIcon: Icon(Icons.find_replace, size: 18),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(findReplaceReplacementProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<SheetSearchScope>(
            segments: const [
              ButtonSegment(
                value: SheetSearchScope.cellValues,
                icon: Icon(Icons.text_fields, size: 16),
                label: Text('Values'),
              ),
              ButtonSegment(
                value: SheetSearchScope.formulas,
                icon: Icon(Icons.functions, size: 16),
                label: Text('Formulas'),
              ),
              ButtonSegment(
                value: SheetSearchScope.all,
                icon: Icon(Icons.all_inclusive, size: 16),
                label: Text('All'),
              ),
            ],
            selected: {scope},
            showSelectedIcon: false,
            onSelectionChanged: (next) {
              ref.read(findReplaceScopeProvider.notifier).state = next.first;
              ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Match case',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                Switch(
                  value: matchCase,
                  onChanged: (value) {
                    ref.read(findReplaceMatchCaseProvider.notifier).state =
                        value;
                    ref.read(findReplaceCurrentIndexProvider.notifier).state =
                        0;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: matches.isEmpty
                    ? null
                    : () => _move(matches, safeIndex, -1),
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                tooltip: 'Previous match',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: matches.isEmpty
                    ? null
                    : () => _move(matches, safeIndex, 1),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                tooltip: 'Next match',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('ky-sheet-replace-current'),
                  onPressed: matches.isEmpty || query.isEmpty
                      ? null
                      : () => _replaceCurrent(
                          matches[safeIndex],
                          query,
                          replacement,
                          options,
                        ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Replace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('ky-sheet-replace-all'),
            onPressed: matches.isEmpty || query.isEmpty
                ? null
                : () => _replaceAll(matches, query, replacement, options),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Replace All'),
          ),
          const SizedBox(height: 16),
          _ResultsHeader(matchCount: matches.length, query: query),
          const SizedBox(height: 8),
          if (query.isEmpty)
            const _EmptyState(
              icon: Icons.search,
              label: 'Enter text to find matches',
            )
          else if (matches.isEmpty)
            const _EmptyState(icon: Icons.search_off, label: 'No matches')
          else
            for (var index = 0; index < matches.length; index++)
              _ResultTile(
                match: matches[index],
                selected: index == safeIndex,
                onTap: () {
                  ref.read(findReplaceCurrentIndexProvider.notifier).state =
                      index;
                  _selectMatch(matches, index);
                },
              ),
        ],
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
  }

  String _matchCounter(int matchCount, int currentIndex) {
    return matchCount == 0 ? '0' : '${currentIndex + 1}/$matchCount';
  }

  void _move(List<SheetSearchMatch> matches, int currentIndex, int delta) {
    if (matches.isEmpty) return;
    final next = (currentIndex + delta + matches.length) % matches.length;
    ref.read(findReplaceCurrentIndexProvider.notifier).state = next;
    _selectMatch(matches, next);
  }

  void _selectMatch(List<SheetSearchMatch> matches, int index) {
    if (matches.isEmpty) return;
    ref
        .read(sheetNavigationControllerProvider)
        .goTo(CellSelection.single(matches[index].address));
  }

  void _replaceCurrent(
    SheetSearchMatch match,
    String query,
    String replacement,
    SheetSearchOptions options,
  ) {
    ref
        .read(sheetNavigationControllerProvider)
        .goTo(CellSelection.single(match.address));
    final count = ref
        .read(spreadsheetProvider.notifier)
        .replaceSearchMatch(match, query, replacement, options: options);
    if (count > 0) {
      ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
    }
  }

  void _replaceAll(
    List<SheetSearchMatch> matches,
    String query,
    String replacement,
    SheetSearchOptions options,
  ) {
    ref
        .read(spreadsheetProvider.notifier)
        .replaceSearchMatches(matches, query, replacement, options: options);
    ref.read(findReplaceCurrentIndexProvider.notifier).state = 0;
  }
}

/// Header row for the find result list.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.matchCount, required this.query});

  final int matchCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.list_alt, color: KySheetColors.mutedText, size: 18),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Results',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          query.isEmpty ? 'Ready' : '$matchCount found',
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Selectable search result preview with its target cell and search scope.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.match,
    required this.selected,
    required this.onTap,
  });

  final SheetSearchMatch match;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? KySheetColors.accentSoft : KySheetColors.surface,
            border: Border.all(
              color: selected ? KySheetColors.accent : KySheetColors.gridLine,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.address.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TargetPill(label: match.targetLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _preview(match.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _preview(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 90) return normalized;
    return '${normalized.substring(0, 87)}...';
  }
}

/// Compact label that identifies where a search result was matched.
class _TargetPill extends StatelessWidget {
  const _TargetPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Neutral placeholder shown before a query exists or when no matches remain.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});

  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: KySheetColors.mutedText, size: 22),
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
