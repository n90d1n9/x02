import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Callback bundle for workbook sheet tab menu actions.
class SheetTabActionMenuCallbacks {
  const SheetTabActionMenuCallbacks({
    required this.onRename,
    required this.onDuplicate,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onColor,
    required this.onHide,
    required this.onDelete,
  });

  /// Called when the rename action is selected.
  final VoidCallback onRename;

  /// Called when the duplicate action is selected.
  final VoidCallback onDuplicate;

  /// Called when the move-left action is selected.
  final VoidCallback onMoveLeft;

  /// Called when the move-right action is selected.
  final VoidCallback onMoveRight;

  /// Called when the tab color action is selected.
  final VoidCallback onColor;

  /// Called when the hide action is selected.
  final VoidCallback onHide;

  /// Called when the delete action is selected.
  final VoidCallback onDelete;

  /// Runs the callback associated with a selected sheet tab action.
  void invoke(SheetTabAction action) {
    switch (action) {
      case SheetTabAction.rename:
        onRename();
      case SheetTabAction.duplicate:
        onDuplicate();
      case SheetTabAction.moveLeft:
        onMoveLeft();
      case SheetTabAction.moveRight:
        onMoveRight();
      case SheetTabAction.color:
        onColor();
      case SheetTabAction.hide:
        onHide();
      case SheetTabAction.delete:
        onDelete();
    }
  }
}

/// Opens the sheet tab context menu at the pointer location.
Future<void> showSheetTabActionContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required Color? tabColor,
  required bool canMoveLeft,
  required bool canMoveRight,
  required bool canDelete,
  required bool canHide,
  required SheetTabActionMenuCallbacks callbacks,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final localPosition = overlay.globalToLocal(globalPosition);
  final action = await showMenu<SheetTabAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(localPosition.dx, localPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: sheetTabActionMenuItems(
      tabColor: tabColor,
      canMoveLeft: canMoveLeft,
      canMoveRight: canMoveRight,
      canDelete: canDelete,
      canHide: canHide,
    ),
  );

  if (action == null) return;
  callbacks.invoke(action);
}

/// Icon menu button for actions that operate on a workbook sheet tab.
class SheetTabActionMenuButton extends StatelessWidget {
  const SheetTabActionMenuButton({
    super.key,
    required this.sheetId,
    this.tabColor,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.canDelete,
    required this.canHide,
    required this.callbacks,
  });

  /// Stable sheet id used by tests and action menu keys.
  final String sheetId;

  /// Current optional tab color shown in the menu.
  final Color? tabColor;

  /// Whether the move-left menu item is enabled.
  final bool canMoveLeft;

  /// Whether the move-right menu item is enabled.
  final bool canMoveRight;

  /// Whether the delete menu item is enabled.
  final bool canDelete;

  /// Whether the hide menu item is enabled.
  final bool canHide;

  /// Callback bundle invoked when a menu item is selected.
  final SheetTabActionMenuCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SheetTabAction>(
      tooltip: 'Sheet Actions',
      padding: EdgeInsets.zero,
      onSelected: callbacks.invoke,
      itemBuilder: (context) => sheetTabActionMenuItems(
        tabColor: tabColor,
        canMoveLeft: canMoveLeft,
        canMoveRight: canMoveRight,
        canDelete: canDelete,
        canHide: canHide,
      ),
      child: SizedBox(
        key: ValueKey('ky-sheet-tab-actions-$sheetId'),
        width: 32,
        height: 32,
        child: const Icon(Icons.more_horiz, size: 18),
      ),
    );
  }
}

/// Supported context actions for workbook sheet tabs.
enum SheetTabAction {
  rename,
  duplicate,
  moveLeft,
  moveRight,
  color,
  hide,
  delete,
}

/// Builds the shared action rows for sheet tab button and context menus.
List<PopupMenuEntry<SheetTabAction>> sheetTabActionMenuItems({
  required Color? tabColor,
  required bool canMoveLeft,
  required bool canMoveRight,
  required bool canDelete,
  required bool canHide,
}) {
  return [
    const PopupMenuItem(
      value: SheetTabAction.rename,
      child: _SheetTabActionMenuItem(
        icon: Icons.edit_outlined,
        label: 'Rename',
      ),
    ),
    const PopupMenuItem(
      value: SheetTabAction.duplicate,
      child: _SheetTabActionMenuItem(
        icon: Icons.copy_outlined,
        label: 'Duplicate',
      ),
    ),
    PopupMenuItem(
      value: SheetTabAction.moveLeft,
      enabled: canMoveLeft,
      child: const _SheetTabActionMenuItem(
        icon: Icons.keyboard_arrow_left,
        label: 'Move Left',
      ),
    ),
    PopupMenuItem(
      value: SheetTabAction.moveRight,
      enabled: canMoveRight,
      child: const _SheetTabActionMenuItem(
        icon: Icons.keyboard_arrow_right,
        label: 'Move Right',
      ),
    ),
    PopupMenuItem(
      value: SheetTabAction.color,
      child: _SheetTabActionMenuItem(
        icon: Icons.palette_outlined,
        label: 'Tab Color',
        swatchColor: tabColor,
      ),
    ),
    PopupMenuItem(
      value: SheetTabAction.hide,
      enabled: canHide,
      child: const _SheetTabActionMenuItem(
        icon: Icons.visibility_off_outlined,
        label: 'Hide Sheet',
      ),
    ),
    const PopupMenuDivider(),
    PopupMenuItem(
      value: SheetTabAction.delete,
      enabled: canDelete,
      child: const _SheetTabActionMenuItem(
        icon: Icons.delete_outline,
        label: 'Delete',
        destructive: true,
      ),
    ),
  ];
}

/// Menu row with an icon and label for sheet tab actions.
class _SheetTabActionMenuItem extends StatelessWidget {
  const _SheetTabActionMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.swatchColor,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? KySheetColors.validationError : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
        if (swatchColor != null) ...[
          const SizedBox(width: 16),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: swatchColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: KySheetColors.gridLineStrong),
            ),
          ),
        ],
      ],
    );
  }
}
