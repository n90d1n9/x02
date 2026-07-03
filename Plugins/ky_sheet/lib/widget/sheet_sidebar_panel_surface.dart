import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Reusable chrome for sidebar panels in the spreadsheet workspace.
class SheetSidebarPanelSurface extends StatelessWidget {
  const SheetSidebarPanelSurface({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.footer,
    this.width = 312,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final double width;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('ky-sheet-sidebar-panel-surface-$title'),
      width: width,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetSidebarPanelHeader(
            icon: icon,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onClose: onClose,
          ),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(child: child),
          if (footer != null) ...[
            const Divider(height: 1, color: KySheetColors.gridLine),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Compact numeric badge for sidebar panel headers.
class SheetSidebarPanelCountBadge extends StatelessWidget {
  const SheetSidebarPanelCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Compact text badge for sidebar panel header metadata.
class SheetSidebarPanelLabelBadge extends StatelessWidget {
  const SheetSidebarPanelLabelBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Header row used by the shared sidebar panel surface.
class _SheetSidebarPanelHeader extends StatelessWidget {
  const _SheetSidebarPanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KySheetColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: KySheetColors.accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              key: ValueKey('ky-sheet-sidebar-panel-close-$title'),
              tooltip: 'Close $title panel',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: KySheetColors.mutedText,
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
