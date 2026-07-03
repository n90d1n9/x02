import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_data_profile.dart';
import '../model/sheet_selection_summary.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_data_profiler.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for profiling selected sheet data and surfacing quality signals.
class SheetDataInsightsPanel extends ConsumerWidget {
  const SheetDataInsightsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = SheetDataProfiler.profile(
      selection: ref.watch(selectedCellProvider),
      cells: ref.watch(spreadsheetProvider),
    );

    return SheetSidebarPanelSurface(
      icon: Icons.insights,
      title: 'Data Insights',
      subtitle: 'Profile selected data',
      trailing: SheetSidebarPanelLabelBadge(label: _profileLabel(profile)),
      onClose: onClose,
      child: profile.hasCells
          ? _ProfileBody(profile: profile)
          : const _EmptyInsights(),
    );
  }

  String _profileLabel(SheetDataProfile profile) {
    return profile.fromSelection ? profile.label : 'Used ${profile.label}';
  }
}

/// Scrollable profile report for the active data range.
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final SheetDataProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.dataset_outlined,
                label: 'Filled',
                value: '${profile.filledCells}/${profile.totalCells}',
                detail: _formatPercent(profile.fillRate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: Icons.pin_outlined,
                label: 'Numeric',
                value: profile.numericCells.toString(),
                detail: _formatPercent(profile.numericRate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.functions,
                label: 'Formulas',
                value: profile.formulaCells.toString(),
                detail: _formatPercent(profile.formulaRate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: profile.hasQualityWarnings
                    ? Icons.warning_amber
                    : Icons.verified_outlined,
                label: 'Issues',
                value: profile.invalidCells.toString(),
                detail: '${profile.duplicateValueCells} dupes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProgressSection(profile: profile),
        if (profile.hasNumericValues) ...[
          const SizedBox(height: 14),
          _NumericSummary(profile: profile),
        ],
        if (profile.histogram.isNotEmpty) ...[
          const SizedBox(height: 14),
          _HistogramSection(profile: profile),
        ],
        if (profile.topValues.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TopValuesSection(profile: profile),
        ],
      ],
    );
  }

  static String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }
}

/// Metric card used at the top of the data insights report.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: KySheetColors.accent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
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
    );
  }
}

/// Composition section for filled, blank, and text ratios.
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.profile});

  final SheetDataProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.stacked_bar_chart,
      title: 'Composition',
      child: Column(
        children: [
          _ProgressRow(
            label: 'Filled',
            value: profile.fillRate,
            detail: '${profile.filledCells} filled',
          ),
          const SizedBox(height: 8),
          _ProgressRow(
            label: 'Blank',
            value: profile.totalCells == 0
                ? 0
                : profile.blankCells / profile.totalCells,
            detail: '${profile.blankCells} blank',
          ),
          const SizedBox(height: 8),
          _ProgressRow(
            label: 'Text',
            value: profile.filledCells == 0
                ? 0
                : profile.textCells / profile.filledCells,
            detail: '${profile.textCells} text',
          ),
        ],
      ),
    );
  }
}

/// Numeric aggregate summary for selected numeric cells.
class _NumericSummary extends StatelessWidget {
  const _NumericSummary({required this.profile});

  final SheetDataProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.calculate_outlined,
      title: 'Numeric Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStat(label: 'Sum', value: _format(profile.sum)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(
                  label: 'Average',
                  value: _format(profile.average ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CompactStat(label: 'Min', value: _format(profile.min!)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(label: 'Max', value: _format(profile.max!)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(double value) {
    return SheetSelectionSummary.formatNumber(value);
  }
}

/// Histogram section for numeric value distribution.
class _HistogramSection extends StatelessWidget {
  const _HistogramSection({required this.profile});

  final SheetDataProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.bar_chart,
      title: 'Distribution',
      child: Column(
        children: [
          for (final bucket in profile.histogram) ...[
            _BarRow(
              label: bucket.label,
              count: bucket.count,
              ratio: bucket.shareOf(profile.numericCells),
            ),
            if (bucket != profile.histogram.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

/// Top repeated values section with navigation to the first matching cell.
class _TopValuesSection extends ConsumerWidget {
  const _TopValuesSection({required this.profile});

  final SheetDataProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      icon: Icons.format_list_numbered,
      title: 'Top Values',
      child: Column(
        children: [
          for (final value in profile.topValues) ...[
            _BarRow(
              label: value.value,
              count: value.count,
              ratio: value.shareOf(profile.filledCells),
              onTap: value.firstAddress == null
                  ? null
                  : () {
                      ref
                          .read(sheetNavigationControllerProvider)
                          .goTo(CellSelection.single(value.firstAddress!));
                    },
            ),
            if (value != profile.topValues.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

/// Reusable boxed section with an icon heading.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: KySheetColors.mutedText, size: 17),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Labeled progress row for composition and distribution metrics.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              detail,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1).toDouble(),
            minHeight: 7,
            backgroundColor: KySheetColors.surfaceMuted,
            color: KySheetColors.accent,
          ),
        ),
      ],
    );
  }
}

/// Horizontal bar row for histogram and top-value entries.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.count,
    required this.ratio,
    this.onTap,
  });

  final String label;
  final int count;
  final double ratio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: KySheetColors.mutedText,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: KySheetColors.surfaceMuted,
              color: KySheetColors.formula,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}

/// Compact numeric statistic cell.
class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown before the sheet has data to profile.
class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, color: KySheetColors.mutedText, size: 28),
            SizedBox(height: 10),
            Text(
              'Select cells or add data to see insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
