import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/sheet_search_match.dart';
import '../utils/sheet_find_replace_engine.dart';
import 'spreadsheet_provider.dart';

/// Input field focus targets supported by the find and replace sidebar.
enum SheetFindReplaceFocusTarget { find, replace }

final findReplaceQueryProvider = StateProvider<String>((ref) => '');
final findReplaceReplacementProvider = StateProvider<String>((ref) => '');
final findReplaceMatchCaseProvider = StateProvider<bool>((ref) => false);
final findReplaceScopeProvider = StateProvider<SheetSearchScope>(
  (ref) => SheetSearchScope.cellValues,
);
final findReplaceCurrentIndexProvider = StateProvider<int>((ref) => 0);
final findReplaceFocusTargetProvider =
    StateProvider<SheetFindReplaceFocusTarget?>((ref) => null);

final findReplaceOptionsProvider = Provider<SheetSearchOptions>((ref) {
  return SheetSearchOptions(
    matchCase: ref.watch(findReplaceMatchCaseProvider),
    scope: ref.watch(findReplaceScopeProvider),
  );
});

final findReplaceMatchesProvider = Provider<List<SheetSearchMatch>>((ref) {
  return SheetFindReplaceEngine.findMatches(
    cells: ref.watch(spreadsheetProvider),
    query: ref.watch(findReplaceQueryProvider),
    options: ref.watch(findReplaceOptionsProvider),
  );
});
