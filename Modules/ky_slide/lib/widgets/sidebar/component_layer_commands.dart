import 'package:flutter/material.dart';

import 'sidebar_command_grid.dart';

class ComponentLayerCommands extends StatelessWidget {
  final Color accentColor;
  final bool hasHiddenLayers;
  final bool hasLockedLayers;
  final bool canRename;
  final bool hasSelectedLayer;
  final bool canSelectAbove;
  final bool canSelectBelow;
  final VoidCallback onShowAll;
  final VoidCallback onUnlockAll;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSelectAbove;
  final VoidCallback onSelectBelow;
  final VoidCallback onBringToFront;
  final VoidCallback onMoveForward;
  final VoidCallback onMoveBackward;
  final VoidCallback onSendToBack;

  const ComponentLayerCommands({
    super.key,
    required this.accentColor,
    required this.hasHiddenLayers,
    required this.hasLockedLayers,
    required this.canRename,
    required this.hasSelectedLayer,
    required this.canSelectAbove,
    required this.canSelectBelow,
    required this.onShowAll,
    required this.onUnlockAll,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSelectAbove,
    required this.onSelectBelow,
    required this.onBringToFront,
    required this.onMoveForward,
    required this.onMoveBackward,
    required this.onSendToBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SidebarCommandGrid(
          accentColor: accentColor,
          items: [
            SidebarCommandGridItem(
              icon: Icons.visibility_outlined,
              label: 'Show all',
              isEnabled: hasHiddenLayers,
              onPressed: onShowAll,
            ),
            SidebarCommandGridItem(
              icon: Icons.lock_open_outlined,
              label: 'Unlock all',
              isEnabled: hasLockedLayers,
              onPressed: onUnlockAll,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SidebarCommandGrid(
          columns: 3,
          accentColor: accentColor,
          items: [
            SidebarCommandGridItem(
              icon: Icons.drive_file_rename_outline,
              label: 'Rename',
              isEnabled: canRename,
              onPressed: onRename,
            ),
            SidebarCommandGridItem(
              icon: Icons.control_point_duplicate,
              label: 'Duplicate',
              isEnabled: hasSelectedLayer,
              onPressed: onDuplicate,
            ),
            SidebarCommandGridItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isEnabled: hasSelectedLayer,
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SidebarCommandGrid(
          accentColor: accentColor,
          items: [
            SidebarCommandGridItem(
              icon: Icons.north,
              label: 'Above',
              isEnabled: canSelectAbove,
              onPressed: onSelectAbove,
            ),
            SidebarCommandGridItem(
              icon: Icons.south,
              label: 'Below',
              isEnabled: canSelectBelow,
              onPressed: onSelectBelow,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SidebarCommandGrid(
          accentColor: accentColor,
          items: [
            SidebarCommandGridItem(
              icon: Icons.flip_to_front,
              label: 'Front',
              isEnabled: hasSelectedLayer,
              onPressed: onBringToFront,
            ),
            SidebarCommandGridItem(
              icon: Icons.keyboard_arrow_up,
              label: 'Forward',
              isEnabled: hasSelectedLayer,
              onPressed: onMoveForward,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SidebarCommandGrid(
          accentColor: accentColor,
          items: [
            SidebarCommandGridItem(
              icon: Icons.keyboard_arrow_down,
              label: 'Backward',
              isEnabled: hasSelectedLayer,
              onPressed: onMoveBackward,
            ),
            SidebarCommandGridItem(
              icon: Icons.flip_to_back,
              label: 'Back',
              isEnabled: hasSelectedLayer,
              onPressed: onSendToBack,
            ),
          ],
        ),
      ],
    );
  }
}
