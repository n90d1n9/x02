import 'package:flutter/material.dart';

import '../model/sheet_shortcut.dart';
import '../state/sheet_sidebar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_sidebar_menu.dart';

/// Vertical launcher rail for sheet sidebar panels.
class SheetSidebarRail extends StatelessWidget {
  const SheetSidebarRail({
    super.key,
    required this.activePanel,
    required this.onPanelPressed,
    required this.onClosePressed,
  });

  final SheetSidebarPanel? activePanel;
  final ValueChanged<SheetSidebarPanel> onPanelPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final entry in SheetSidebarMenu.sections.indexed) ...[
                    if (entry.$1 > 0) _SidebarSectionDivider(section: entry.$2),
                    for (final item in entry.$2.items)
                      _SidebarRailButton(
                        key: ValueKey('ky-sheet-sidebar-${item.panel.name}'),
                        icon: item.icon,
                        tooltip: item.tooltip,
                        shortcutLabel: item.shortcutLabel,
                        active: activePanel == item.panel,
                        onPressed: () => onPanelPressed(item.panel),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (activePanel != null)
            _SidebarRailButton(
              key: const ValueKey('ky-sheet-sidebar-close'),
              icon: Icons.close,
              tooltip: 'Close Sidebar',
              shortcutLabel: SheetShortcutLabels.closePanel,
              active: false,
              onPressed: onClosePressed,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarSectionDivider extends StatelessWidget {
  const _SidebarSectionDivider({required this.section});

  final SheetSidebarMenuSection section;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: section.label,
      child: Container(
        key: ValueKey('ky-sheet-sidebar-section-${section.id}'),
        width: 34,
        height: 13,
        alignment: Alignment.center,
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            color: KySheetColors.gridLineStrong,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _SidebarRailButton extends StatelessWidget {
  const _SidebarRailButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.shortcutLabel,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String? shortcutLabel;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltipMessage = shortcutLabel == null
        ? tooltip
        : '$tooltip ($shortcutLabel)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        width: 46,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              left: active ? 0 : -4,
              width: 3,
              height: active ? 22 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: KySheetColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Tooltip(
              message: tooltipMessage,
              child: IconButton.filledTonal(
                onPressed: onPressed,
                icon: Icon(icon, size: 19),
                style: IconButton.styleFrom(
                  foregroundColor: active ? Colors.white : KySheetColors.text,
                  backgroundColor: active
                      ? KySheetColors.accent
                      : KySheetColors.surfaceMuted,
                  hoverColor: active
                      ? KySheetColors.accent
                      : KySheetColors.accentSoft,
                  minimumSize: const Size.square(38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
