import 'package:flutter/material.dart';

import '../model/sheet_formula_suggestion.dart';
import '../theme/ky_sheet_theme.dart';

class FormulaSuggestionPanel extends StatelessWidget {
  const FormulaSuggestionPanel({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<SheetFormulaSuggestion> suggestions;
  final ValueChanged<SheetFormulaSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLineStrong),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 248),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: KySheetColors.gridLine),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _FormulaSuggestionTile(
              suggestion: suggestion,
              onTap: () => onSelected(suggestion),
            );
          },
        ),
      ),
    );
  }
}

class _FormulaSuggestionTile extends StatelessWidget {
  const _FormulaSuggestionTile({required this.suggestion, required this.onTap});

  final SheetFormulaSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRange = suggestion.kind == SheetFormulaSuggestionKind.namedRange;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isRange
                    ? KySheetColors.surfaceMuted
                    : KySheetColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isRange ? Icons.bookmark_border : Icons.functions,
                size: 16,
                color: isRange ? KySheetColors.accent : KySheetColors.formula,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        suggestion.name,
                        style: const TextStyle(
                          color: KySheetColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          suggestion.signature,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KySheetColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    suggestion.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suggestion.category,
              style: const TextStyle(
                color: KySheetColors.formula,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
