import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Icon-only command button used by ribbon and compact sheet tool surfaces.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  /// Icon that represents the command.
  final IconData icon;

  /// Callback invoked when the command is available and pressed.
  final VoidCallback? onPressed;

  /// Tooltip text shown for command discovery.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final buttonSize = density.commandButtonSize;

    return Tooltip(
      message: tooltip ?? '',
      child: IconButton.filledTonal(
        icon: Icon(icon, size: density.commandIconSize),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: KySheetColors.text,
          disabledForegroundColor: KySheetColors.mutedText.withValues(
            alpha: 0.38,
          ),
          backgroundColor: KySheetColors.surfaceMuted,
          disabledBackgroundColor: KySheetColors.surfaceMuted.withValues(
            alpha: 0.55,
          ),
          hoverColor: KySheetColors.accentSoft,
          fixedSize: Size.square(buttonSize),
          minimumSize: Size.square(buttonSize),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
