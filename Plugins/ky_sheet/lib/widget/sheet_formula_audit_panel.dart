import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_audit.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_formula_auditor.dart';
import '../utils/sheet_formula_error_status.dart';
import '../utils/sheet_formula_trace_builder.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for inspecting formula references, dependents, and errors.
class SheetFormulaAuditPanel extends ConsumerWidget {
  const SheetFormulaAuditPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = SheetFormulaAuditor.inspect(
      selection: ref.watch(selectedCellProvider),
      cells: ref.watch(spreadsheetProvider),
      namedRanges: ref.watch(sheetNamedRangesProvider),
    );

    return SheetSidebarPanelSurface(
      icon: Icons.schema_outlined,
      title: 'Formula Audit',
      subtitle: 'Trace formulas',
      trailing: SheetSidebarPanelLabelBadge(label: audit.selectionLabel),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: audit.hasSelection
                ? _AuditBody(audit: audit)
                : const _EmptyAudit(),
          ),
        ],
      ),
    );
  }
}

class _AuditBody extends ConsumerWidget {
  const _AuditBody({required this.audit});

  final SheetFormulaAudit audit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = SheetFormulaErrorStatus.fromCode(audit.result);
    final hasFormulaError = audit.hasFormula && audit.result.startsWith('#');
    final hasActiveTrace = ref
        .watch(formulaReferencePreviewProvider)
        .isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (audit.hasFormula)
          _FormulaCard(
            audit: audit,
            status: hasFormulaError ? status : SheetFormulaErrorStatus.none,
          )
        else
          _NoFormulaCard(audit: audit),
        const SizedBox(height: 10),
        _TraceActions(
          audit: audit,
          hasActiveTrace: hasActiveTrace,
          onTrace: (mode) => _trace(ref, mode),
          onClear: () => _clearTrace(ref),
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          icon: Icons.call_split_outlined,
          title: 'References',
          count: audit.references.length,
        ),
        const SizedBox(height: 8),
        if (audit.references.isEmpty)
          const _EmptySection(text: 'No references found')
        else
          for (final reference in audit.references) ...[
            _ReferenceTile(
              label: reference.label,
              subtitle: 'Used by ${audit.addressLabel}',
              icon: Icons.arrow_outward,
              onTap: () => ref
                  .read(sheetNavigationControllerProvider)
                  .goTo(reference.selection),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 14),
        _SectionHeader(
          icon: Icons.account_tree_outlined,
          title: 'Dependents',
          count: audit.dependents.length,
        ),
        const SizedBox(height: 8),
        if (audit.dependents.isEmpty)
          const _EmptySection(text: 'No dependent formulas')
        else
          for (final dependent in audit.dependents) ...[
            _DependentTile(
              dependent: dependent,
              onTap: () => ref
                  .read(sheetNavigationControllerProvider)
                  .goTo(CellSelection.single(dependent.address)),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  void _trace(WidgetRef ref, SheetFormulaTraceMode mode) {
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

class _TraceActions extends StatelessWidget {
  const _TraceActions({
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
    return _SectionCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('ky-sheet-trace-references'),
            onPressed: audit.references.isEmpty
                ? null
                : () => onTrace(SheetFormulaTraceMode.references),
            icon: const Icon(Icons.call_split_outlined, size: 16),
            label: const Text('Trace References'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('ky-sheet-trace-dependents'),
            onPressed: audit.dependents.isEmpty
                ? null
                : () => onTrace(SheetFormulaTraceMode.dependents),
            icon: const Icon(Icons.account_tree_outlined, size: 16),
            label: const Text('Trace Dependents'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('ky-sheet-trace-all'),
            onPressed: audit.references.isEmpty && audit.dependents.isEmpty
                ? null
                : () => onTrace(SheetFormulaTraceMode.all),
            icon: const Icon(Icons.hub_outlined, size: 16),
            label: const Text('Trace All'),
          ),
          IconButton.filledTonal(
            key: const ValueKey('ky-sheet-clear-formula-trace'),
            onPressed: hasActiveTrace ? onClear : null,
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            tooltip: 'Clear Formula Trace',
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.audit, required this.status});

  final SheetFormulaAudit audit;
  final SheetFormulaErrorStatus status;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricRow(label: audit.addressLabel, value: audit.result),
          const SizedBox(height: 8),
          SelectableText(
            audit.formula,
            style: const TextStyle(
              color: KySheetColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (status.hasError) ...[
            const SizedBox(height: 10),
            _ErrorCallout(status: status),
          ],
        ],
      ),
    );
  }
}

class _NoFormulaCard extends StatelessWidget {
  const _NoFormulaCard({required this.audit});

  final SheetFormulaAudit audit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          const Icon(Icons.functions, color: KySheetColors.mutedText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${audit.addressLabel} has no formula',
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KySheetColors.accent),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        _CountBadge(count: count),
      ],
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AuditTile(
      icon: icon,
      title: label,
      subtitle: subtitle,
      trailing: const Icon(
        Icons.open_in_new,
        size: 16,
        color: KySheetColors.mutedText,
      ),
      onTap: onTap,
    );
  }
}

class _DependentTile extends StatelessWidget {
  const _DependentTile({required this.dependent, required this.onTap});

  final SheetFormulaAuditDependent dependent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final referenceLabel = dependent.matchedReferences
        .map((selection) => selection.label)
        .join(', ');

    return _AuditTile(
      icon: Icons.functions,
      title: dependent.label,
      subtitle: '$referenceLabel -> ${dependent.result}',
      trailing: const Icon(
        Icons.open_in_new,
        size: 16,
        color: KySheetColors.mutedText,
      ),
      onTap: onTap,
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KySheetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: KySheetColors.gridLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: KySheetColors.accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? 'Blank' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: value.startsWith('#')
                  ? KySheetColors.validationError
                  : KySheetColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({required this.status});

  final SheetFormulaErrorStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.validationSoft,
        border: Border.all(color: KySheetColors.validationError),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Text(
          '${status.title}. ${status.suggestion}',
          style: const TextStyle(
            color: KySheetColors.validationError,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.headerActive),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: KySheetColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyAudit extends StatelessWidget {
  const _EmptyAudit();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Select a cell to audit formulas',
          textAlign: TextAlign.center,
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
