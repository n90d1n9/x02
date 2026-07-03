import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_health.dart';
import '../model/sheet_named_range.dart';
import 'sheet_formula_error_status.dart';
import 'sheet_formula_reference.dart';

class SheetFormulaHealthScanner {
  const SheetFormulaHealthScanner._();

  static SheetFormulaHealth scan(
    Map<CellAddress, CellData> cells, {
    List<SheetNamedRange> namedRanges = const [],
  }) {
    var formulaCount = 0;
    final issues = <SheetFormulaIssue>[];

    for (final entry in cells.entries) {
      final formula = entry.value.formula;
      if (formula == null || formula.trim().isEmpty) continue;

      formulaCount++;
      final status = SheetFormulaErrorStatus.fromCell(entry.value);
      if (!status.hasError) continue;

      issues.add(
        SheetFormulaIssue(
          address: entry.key,
          formula: formula,
          result: entry.value.value,
          code: status.code,
          title: status.title,
          message: status.message,
          suggestion: status.suggestion,
          relatedSelections: _issueSelections(entry.key, formula, namedRanges),
        ),
      );
    }

    issues.addAll(_cycleIssues(cells, namedRanges));
    issues.sort((left, right) {
      final addressComparison = _compareAddress(left.address, right.address);
      return addressComparison == 0
          ? left.code.compareTo(right.code)
          : addressComparison;
    });

    return SheetFormulaHealth(formulaCount: formulaCount, issues: issues);
  }

  static List<SheetFormulaIssue> _cycleIssues(
    Map<CellAddress, CellData> cells,
    List<SheetNamedRange> namedRanges,
  ) {
    final graph = _dependencyGraph(cells, namedRanges);
    final components = _cyclicComponents(graph);
    final issues = <SheetFormulaIssue>[];

    for (final component in components) {
      final cycleLabel = _cycleLabel(component);
      final addresses = component.toList()..sort(_compareAddress);
      final relatedSelections = [
        for (final address in addresses) CellSelection.single(address),
      ];
      for (final address in addresses) {
        final cellData = cells[address];
        issues.add(
          SheetFormulaIssue(
            address: address,
            formula: cellData?.formula ?? '',
            result: cellData?.value ?? '',
            code: '#CYCLE',
            title: 'Circular reference',
            message: 'This formula participates in a circular dependency.',
            suggestion: 'Break the loop: $cycleLabel.',
            relatedSelections: relatedSelections,
          ),
        );
      }
    }

    return issues;
  }

  static List<CellSelection> _issueSelections(
    CellAddress address,
    String formula,
    List<SheetNamedRange> namedRanges,
  ) {
    return _uniqueSelections([
      CellSelection.single(address),
      ...SheetFormulaReference.referencedSelections(
        formula,
        namedRanges: namedRanges,
      ),
    ]);
  }

  static Map<CellAddress, Set<CellAddress>> _dependencyGraph(
    Map<CellAddress, CellData> cells,
    List<SheetNamedRange> namedRanges,
  ) {
    final formulaAddresses = {
      for (final entry in cells.entries)
        if (entry.value.formula?.trim().isNotEmpty == true) entry.key,
    };
    final graph = <CellAddress, Set<CellAddress>>{};

    for (final address in formulaAddresses) {
      final formula = cells[address]?.formula ?? '';
      final dependencies = <CellAddress>{};
      for (final selection in SheetFormulaReference.referencedSelections(
        formula,
        namedRanges: namedRanges,
      )) {
        for (final referencedAddress in selection.getCells()) {
          if (formulaAddresses.contains(referencedAddress)) {
            dependencies.add(referencedAddress);
          }
        }
      }
      graph[address] = dependencies;
    }

    return graph;
  }

  static List<Set<CellAddress>> _cyclicComponents(
    Map<CellAddress, Set<CellAddress>> graph,
  ) {
    var nextIndex = 0;
    final indexes = <CellAddress, int>{};
    final lowLinks = <CellAddress, int>{};
    final stack = <CellAddress>[];
    final onStack = <CellAddress>{};
    final components = <Set<CellAddress>>[];

    void strongConnect(CellAddress address) {
      indexes[address] = nextIndex;
      lowLinks[address] = nextIndex;
      nextIndex++;
      stack.add(address);
      onStack.add(address);

      for (final dependency in graph[address] ?? const <CellAddress>{}) {
        if (!graph.containsKey(dependency)) continue;
        if (!indexes.containsKey(dependency)) {
          strongConnect(dependency);
          lowLinks[address] = _min(lowLinks[address]!, lowLinks[dependency]!);
        } else if (onStack.contains(dependency)) {
          lowLinks[address] = _min(lowLinks[address]!, indexes[dependency]!);
        }
      }

      if (lowLinks[address] != indexes[address]) return;

      final component = <CellAddress>{};
      CellAddress current;
      do {
        current = stack.removeLast();
        onStack.remove(current);
        component.add(current);
      } while (current != address);

      if (component.length > 1 ||
          (graph[address]?.contains(address) ?? false)) {
        components.add(component);
      }
    }

    final addresses = graph.keys.toList()..sort(_compareAddress);
    for (final address in addresses) {
      if (!indexes.containsKey(address)) strongConnect(address);
    }

    components.sort(
      (left, right) =>
          _compareAddress(_firstAddress(left), _firstAddress(right)),
    );
    return components;
  }

  static String _cycleLabel(Set<CellAddress> component) {
    final addresses = component.toList()..sort(_compareAddress);
    if (addresses.length == 1) {
      return '${addresses.first.label} -> ${addresses.first.label}';
    }

    return [
      for (final address in addresses) address.label,
      addresses.first.label,
    ].join(' -> ');
  }

  static List<CellSelection> _uniqueSelections(Iterable<CellSelection> items) {
    final seen = <String>{};
    return [
      for (final selection in items)
        if (seen.add(selection.label)) selection,
    ];
  }

  static CellAddress _firstAddress(Set<CellAddress> addresses) {
    final sorted = addresses.toList()..sort(_compareAddress);
    return sorted.first;
  }

  static int _compareAddress(CellAddress left, CellAddress right) {
    final rowComparison = left.row.compareTo(right.row);
    return rowComparison == 0 ? left.col.compareTo(right.col) : rowComparison;
  }

  static int _min(int left, int right) => left < right ? left : right;
}
