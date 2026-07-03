import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_audit.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../utils/sheet_formula_auditor.dart';
import '../utils/sheet_formula_trace_builder.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';
import 'tool_button.dart';

/// Formula ribbon commands for insertion, libraries, auditing, and tracing.
class SheetRibbonFormulaGroup extends ConsumerWidget {
  const SheetRibbonFormulaGroup({
    super.key,
    required this.controller,
    required this.selection,
    required this.onOpenPanel,
  });

  final ToolbarController controller;
  final CellSelection? selection;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = SheetFormulaAuditor.inspect(
      selection: selection,
      cells: ref.watch(spreadsheetProvider),
      namedRanges: ref.watch(sheetNamedRangesProvider),
    );
    final hasActiveTrace = ref
        .watch(formulaReferencePreviewProvider)
        .isNotEmpty;

    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.functions,
          onPressed: _hasSelection
              ? () => controller.insertFunction(selection!.start, 'SUM')
              : null,
          tooltip: 'AutoSum',
        ),
        _FunctionMenuButton(
          selection: selection,
          onInsert: (functionName) =>
              controller.insertFunction(selection!.start, functionName),
        ),
        ToolButton(
          icon: Icons.library_books_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.functionLibrary),
          tooltip: 'Function Library',
        ),
        ToolButton(
          icon: Icons.schema_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.formulaAudit),
          tooltip: 'Formula Audit',
        ),
        ToolButton(
          icon: Icons.health_and_safety_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.formulaHealth),
          tooltip: 'Formula Health',
        ),
        _FormulaTraceMenuButton(
          audit: audit,
          hasActiveTrace: hasActiveTrace,
          onTrace: (mode) => _trace(ref, audit, mode),
          onClear: () => _clearTrace(ref),
        ),
      ],
    );
  }

  void _trace(
    WidgetRef ref,
    SheetFormulaAudit audit,
    SheetFormulaTraceMode mode,
  ) {
    final selections = SheetFormulaTraceBuilder.build(audit, mode);
    ref.read(formulaReferencePreviewProvider.notifier).state = selections;
    ref
        .read(formulaReferencePreviewContextProvider.notifier)
        .state = selections.isEmpty
        ? null
        : SheetFormulaPreviewContext(
            source: switch (mode) {
              SheetFormulaTraceMode.references =>
                SheetFormulaPreviewSource.traceReferences,
              SheetFormulaTraceMode.dependents =>
                SheetFormulaPreviewSource.traceDependents,
              SheetFormulaTraceMode.all => SheetFormulaPreviewSource.traceAll,
            },
            originLabel: audit.addressLabel,
            targetCount: selections.length,
          );
  }

  void _clearTrace(WidgetRef ref) {
    ref.read(formulaReferencePreviewProvider.notifier).state = const [];
    ref.read(formulaReferencePreviewContextProvider.notifier).state = null;
  }
}

class _FunctionMenuButton extends StatelessWidget {
  const _FunctionMenuButton({required this.selection, required this.onInsert});

  final CellSelection? selection;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selection != null;

    return SheetRibbonMenuButton(
      icon: Icons.calculate_outlined,
      tooltip: 'Insert Function',
      actions: [
        SheetRibbonMenuAction(
          label: 'Average',
          onSelected: hasSelection ? () => onInsert('AVERAGE') : null,
        ),
        SheetRibbonMenuAction(
          label: 'Count',
          onSelected: hasSelection ? () => onInsert('COUNT') : null,
        ),
        SheetRibbonMenuAction(
          label: 'Minimum',
          onSelected: hasSelection ? () => onInsert('MIN') : null,
        ),
        SheetRibbonMenuAction(
          label: 'Maximum',
          onSelected: hasSelection ? () => onInsert('MAX') : null,
        ),
      ],
    );
  }
}

class _FormulaTraceMenuButton extends StatelessWidget {
  const _FormulaTraceMenuButton({
    required this.audit,
    required this.hasActiveTrace,
    required this.onTrace,
    required this.onClear,
  });

  final SheetFormulaAudit audit;
  final bool hasActiveTrace;
  final ValueChanged<SheetFormulaTraceMode> onTrace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonMenuButton(
      icon: Icons.account_tree_outlined,
      tooltip: 'Trace Formula',
      actions: [
        SheetRibbonMenuAction(
          label: 'Trace References',
          onSelected: audit.references.isNotEmpty
              ? () => onTrace(SheetFormulaTraceMode.references)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Trace Dependents',
          onSelected: audit.dependents.isNotEmpty
              ? () => onTrace(SheetFormulaTraceMode.dependents)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Trace All',
          onSelected: audit.references.isNotEmpty || audit.dependents.isNotEmpty
              ? () => onTrace(SheetFormulaTraceMode.all)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Clear Formula Trace',
          onSelected: hasActiveTrace ? onClear : null,
        ),
      ],
    );
  }
}
