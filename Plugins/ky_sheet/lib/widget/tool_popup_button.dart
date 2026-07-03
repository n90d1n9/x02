import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Icon-only popup command button for grouped ribbon options.
class ToolPopupButton<T> extends StatelessWidget {
  const ToolPopupButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.itemBuilder,
    this.onSelected,
    this.enabled = true,
  });

  /// Icon that represents the popup command group.
  final IconData icon;

  /// Tooltip text shown for command discovery.
  final String tooltip;

  /// Builds popup menu items when the button is opened.
  final PopupMenuItemBuilder<T> itemBuilder;

  /// Callback invoked after a popup item is selected.
  final PopupMenuItemSelected<T>? onSelected;

  /// Whether the popup can be opened.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final buttonSize = density.commandButtonSize;
    final foregroundColor = enabled
        ? KySheetColors.text
        : KySheetColors.mutedText.withValues(alpha: 0.38);
    final backgroundColor = enabled
        ? KySheetColors.surfaceMuted
        : KySheetColors.surfaceMuted.withValues(alpha: 0.55);

    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      offset: Offset(0, density.commandPopupOffsetY),
      child: Tooltip(
        message: tooltip,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(buttonSize / 2),
            ),
            child: Icon(
              icon,
              size: density.commandIconSize,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
