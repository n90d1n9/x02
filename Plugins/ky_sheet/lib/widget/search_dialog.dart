import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../state/spreadsheet_provider.dart';

class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({super.key});

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog> {
  final _searchController = TextEditingController();
  final _replaceController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final currentIndex = ref.watch(currentSearchIndexProvider);

    return AlertDialog(
      title: const Text('Find & Replace'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Find',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replaceController,
              decoration: const InputDecoration(labelText: 'Replace with'),
            ),
            const SizedBox(height: 16),
            if (results.isNotEmpty)
              Text(
                '${currentIndex + 1} of ${results.length} results',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (results.isNotEmpty) ...[
          TextButton(onPressed: _previousResult, child: const Text('Previous')),
          TextButton(onPressed: _nextResult, child: const Text('Next')),
          TextButton(onPressed: _replaceOne, child: const Text('Replace')),
        ],
        ElevatedButton(
          onPressed: _replaceAll,
          child: const Text('Replace All'),
        ),
      ],
    );
  }

  void _performSearch() {
    final query = _searchController.text;
    final results = ref.read(spreadsheetProvider.notifier).search(query);
    ref.read(searchResultsProvider.notifier).state = results;
    ref.read(currentSearchIndexProvider.notifier).state = 0;
    if (results.isNotEmpty) {
      ref.read(selectedCellProvider.notifier).state = CellSelection(results[0]);
    }
  }

  void _nextResult() {
    final results = ref.read(searchResultsProvider);
    if (results.isEmpty) return;
    final current = ref.read(currentSearchIndexProvider);
    final next = (current + 1) % results.length;
    ref.read(currentSearchIndexProvider.notifier).state = next;
    ref.read(selectedCellProvider.notifier).state = CellSelection(
      results[next],
    );
  }

  void _previousResult() {
    final results = ref.read(searchResultsProvider);
    if (results.isEmpty) return;
    final current = ref.read(currentSearchIndexProvider);
    final prev = (current - 1 + results.length) % results.length;
    ref.read(currentSearchIndexProvider.notifier).state = prev;
    ref.read(selectedCellProvider.notifier).state = CellSelection(
      results[prev],
    );
  }

  void _replaceOne() {
    final results = ref.read(searchResultsProvider);
    final current = ref.read(currentSearchIndexProvider);
    if (results.isEmpty) return;

    final addr = results[current];
    ref
        .read(spreadsheetProvider.notifier)
        .updateCellValue(addr, _replaceController.text);
    _performSearch(); // Refresh results
  }

  void _replaceAll() {
    ref
        .read(spreadsheetProvider.notifier)
        .replaceAll(_searchController.text, _replaceController.text);
    _performSearch(); // Refresh results
  }
}
