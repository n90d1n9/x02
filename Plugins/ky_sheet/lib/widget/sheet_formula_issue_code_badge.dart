import 'package:flutter/material.dart';

import '../model/sheet_formula_issue_code_info.dart';
import '../theme/ky_sheet_theme.dart';

class SheetFormulaIssueCodeBadge extends StatelessWidget {
  const SheetFormulaIssueCodeBadge({
    super.key,
    required this.code,
    this.showLabel = true,
  });

  final String code;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final info = SheetFormulaIssueCodeCatalog.describe(code);

    return Tooltip(
      message: '${info.label} (${info.code}). ${info.description}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KySheetColors.validationSoft,
          border: Border.all(color: KySheetColors.validationError),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel) ...[
                Flexible(
                  child: Text(
                    info.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.validationError,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                info.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KySheetColors.validationError,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
