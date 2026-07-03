import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_search_match.dart';

class SheetFindReplaceEngine {
  const SheetFindReplaceEngine._();

  static List<SheetSearchMatch> findMatches({
    required Map<CellAddress, CellData> cells,
    required String query,
    SheetSearchOptions options = const SheetSearchOptions(),
  }) {
    if (query.isEmpty) return const [];

    final entries = cells.entries.toList()
      ..sort((a, b) {
        final rowCompare = a.key.row.compareTo(b.key.row);
        return rowCompare == 0 ? a.key.col.compareTo(b.key.col) : rowCompare;
      });
    final matches = <SheetSearchMatch>[];

    for (final entry in entries) {
      if (options.includeValues) {
        final match = _firstMatch(
          address: entry.key,
          target: SheetSearchTarget.value,
          text: entry.value.value,
          query: query,
          matchCase: options.matchCase,
        );
        if (match != null) matches.add(match);
      }

      final formula = entry.value.formula;
      if (options.includeFormulas && formula != null) {
        final match = _firstMatch(
          address: entry.key,
          target: SheetSearchTarget.formula,
          text: formula,
          query: query,
          matchCase: options.matchCase,
        );
        if (match != null) matches.add(match);
      }
    }

    return matches;
  }

  static CellData replaceTargetsInCell({
    required CellData cell,
    required Set<SheetSearchTarget> targets,
    required String find,
    required String replacement,
    required SheetSearchOptions options,
    bool replaceFirstOnly = false,
  }) {
    var nextValue = cell.value;
    var nextFormula = cell.formula;
    var clearFormula = false;

    if (targets.contains(SheetSearchTarget.value)) {
      nextValue = replaceText(
        source: nextValue,
        find: find,
        replacement: replacement,
        matchCase: options.matchCase,
        replaceFirstOnly: replaceFirstOnly,
      );
      clearFormula =
          cell.formula != null && !targets.contains(SheetSearchTarget.formula);
    }

    if (targets.contains(SheetSearchTarget.formula) && nextFormula != null) {
      nextFormula = replaceText(
        source: nextFormula,
        find: find,
        replacement: replacement,
        matchCase: options.matchCase,
        replaceFirstOnly: replaceFirstOnly,
      );
    }

    if (clearFormula) {
      return cell.copyWith(value: nextValue, clearFormula: true);
    }

    return cell.copyWith(value: nextValue, formula: nextFormula);
  }

  static String replaceText({
    required String source,
    required String find,
    required String replacement,
    required bool matchCase,
    bool replaceFirstOnly = false,
  }) {
    if (source.isEmpty || find.isEmpty) return source;

    final searchableSource = matchCase ? source : source.toLowerCase();
    final searchableFind = matchCase ? find : find.toLowerCase();
    final buffer = StringBuffer();
    var cursor = 0;
    var replaced = false;

    while (cursor < source.length) {
      final index = searchableSource.indexOf(searchableFind, cursor);
      if (index == -1) break;

      buffer
        ..write(source.substring(cursor, index))
        ..write(replacement);
      cursor = index + find.length;
      replaced = true;

      if (replaceFirstOnly) break;
    }

    if (!replaced) return source;
    buffer.write(source.substring(cursor));
    return buffer.toString();
  }

  static SheetSearchMatch? _firstMatch({
    required CellAddress address,
    required SheetSearchTarget target,
    required String text,
    required String query,
    required bool matchCase,
  }) {
    if (text.isEmpty) return null;

    final searchableText = matchCase ? text : text.toLowerCase();
    final searchableQuery = matchCase ? query : query.toLowerCase();
    final start = searchableText.indexOf(searchableQuery);
    if (start == -1) return null;

    return SheetSearchMatch(
      address: address,
      target: target,
      text: text,
      start: start,
      end: start + query.length,
    );
  }
}
