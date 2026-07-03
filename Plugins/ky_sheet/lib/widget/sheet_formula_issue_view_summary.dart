import 'package:flutter/material.dart';

import '../model/sheet_formula_issue_view_state.dart';
import '../theme/ky_sheet_theme.dart';

class SheetFormulaIssueViewSummary extends StatelessWidget {
  const SheetFormulaIssueViewSummary({
    super.key,
    required this.viewState,
    this.onReset,
  });

  final SheetFormulaIssueViewState viewState;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('ky-sheet-formula-health-view-summary'),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.tune_outlined,
                size: 18,
                color: KySheetColors.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewState.countLabel,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (viewState.activeBadges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final badge in viewState.activeBadges)
                          _ViewBadge(label: badge),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (viewState.canReset && onReset != null) ...[
              const SizedBox(width: 6),
              IconButton.filledTonal(
                key: const ValueKey('ky-sheet-formula-health-view-reset'),
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                padding: EdgeInsets.zero,
                iconSize: 16,
                tooltip: 'Reset Formula Issue View',
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewBadge extends StatelessWidget {
  const _ViewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
