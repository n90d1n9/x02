import 'package:flutter/material.dart';

import '../model/sheet_formula_health.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_formula_issue_guidance.dart';
import 'sheet_formula_issue_code_badge.dart';

class SheetFormulaIssueDetailCard extends StatelessWidget {
  const SheetFormulaIssueDetailCard({
    super.key,
    required this.issue,
    required this.onTrace,
    required this.onCopy,
    required this.onFocus,
  });

  final SheetFormulaIssue issue;
  final VoidCallback onTrace;
  final VoidCallback onCopy;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final relatedSelections = issue.relatedSelections;
    final guidance = SheetFormulaIssueGuidanceBuilder.build(issue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        border: Border.all(color: KySheetColors.accent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.plagiarism_outlined,
                  color: KySheetColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Selected Issue',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
                _IssueBadge(label: issue.label),
                const SizedBox(width: 6),
                SheetFormulaIssueCodeBadge(code: issue.code, showLabel: false),
              ],
            ),
            const SizedBox(height: 10),
            _DetailRow(label: 'Formula', value: issue.formula, monospace: true),
            const SizedBox(height: 8),
            _DetailRow(label: 'Result', value: issue.result),
            const SizedBox(height: 8),
            _DetailRow(label: 'Problem', value: issue.message),
            const SizedBox(height: 8),
            _DetailRow(label: 'Suggestion', value: issue.suggestion),
            const SizedBox(height: 10),
            _GuidanceBlock(guidance: guidance),
            if (relatedSelections.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Related',
                style: TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final selection in relatedSelections)
                    _IssueBadge(label: selection.label),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('ky-sheet-trace-selected-formula-issue'),
                  onPressed: onTrace,
                  icon: const Icon(Icons.schema_outlined, size: 16),
                  label: const Text('Trace'),
                ),
                TextButton.icon(
                  key: const ValueKey('ky-sheet-copy-selected-formula-issue'),
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  key: const ValueKey('ky-sheet-focus-selected-formula-issue'),
                  onPressed: onFocus,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Focus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceBlock extends StatelessWidget {
  const _GuidanceBlock({required this.guidance});

  final SheetFormulaIssueGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  color: KySheetColors.formula,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    guidance.title,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            for (final check in guidance.checks) _GuidanceCheck(text: check),
          ],
        ),
      ),
    );
  }
}

class _GuidanceCheck extends StatelessWidget {
  const _GuidanceCheck({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check, color: KySheetColors.formula, size: 12),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: KySheetColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: TextStyle(
            color: KySheetColors.text,
            fontSize: 12,
            fontFamily: monospace ? 'monospace' : null,
            fontWeight: monospace ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _IssueBadge extends StatelessWidget {
  const _IssueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
