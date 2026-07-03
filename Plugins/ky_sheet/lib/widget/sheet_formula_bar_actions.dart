import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetFormulaBarActions extends StatelessWidget {
  const SheetFormulaBarActions({
    super.key,
    required this.canCancel,
    required this.canCommit,
    required this.onCancel,
    required this.onCommit,
  });

  final bool canCancel;
  final bool canCommit;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormulaActionButton(
          key: const ValueKey('ky-sheet-formula-cancel'),
          icon: Icons.close,
          tooltip: 'Cancel Edit',
          enabled: canCancel,
          onPressed: onCancel,
        ),
        const SizedBox(width: 4),
        _FormulaActionButton(
          key: const ValueKey('ky-sheet-formula-commit'),
          icon: Icons.check,
          tooltip: 'Apply Edit',
          enabled: canCommit,
          emphasized: true,
          onPressed: onCommit,
        ),
      ],
    );
  }
}

class _FormulaActionButton extends StatelessWidget {
  const _FormulaActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background = emphasized
        ? KySheetColors.accentSoft
        : KySheetColors.surfaceMuted;
    final foreground = emphasized ? KySheetColors.accent : KySheetColors.text;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.42,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? background : KySheetColors.surfaceMuted,
              border: Border.all(color: KySheetColors.gridLine),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}
