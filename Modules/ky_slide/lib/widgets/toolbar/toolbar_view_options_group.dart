import 'package:flutter/material.dart';

import '../../models/canvas_grid_preset.dart';
import 'ribbon_toggle_button.dart';
import 'toolbar_grid_preset_menu.dart';

/// View ribbon group for toggling canvas aids and speaker notes.
class ToolbarViewOptionsGroup extends StatelessWidget {
  final bool showRuler;
  final bool showGrid;
  final bool snapToGrid;
  final CanvasGridPreset gridPreset;
  final bool showSpeakerNotes;
  final VoidCallback onToggleRuler;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnapToGrid;
  final ValueChanged<CanvasGridPreset> onGridPresetSelected;
  final VoidCallback onToggleSpeakerNotes;
  final bool compact;

  const ToolbarViewOptionsGroup({
    super.key,
    required this.showRuler,
    required this.showGrid,
    required this.snapToGrid,
    required this.gridPreset,
    required this.showSpeakerNotes,
    required this.onToggleRuler,
    required this.onToggleGrid,
    required this.onToggleSnapToGrid,
    required this.onGridPresetSelected,
    required this.onToggleSpeakerNotes,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonToggleButton(
          activeIcon: Icons.straighten,
          inactiveIcon: Icons.straighten_outlined,
          tooltip: 'Toggle Ruler',
          isActive: showRuler,
          onPressed: onToggleRuler,
          compact: compact,
        ),
        RibbonToggleButton(
          activeIcon: Icons.grid_on,
          inactiveIcon: Icons.grid_off,
          tooltip: 'Toggle Grid',
          isActive: showGrid,
          onPressed: onToggleGrid,
          compact: compact,
        ),
        RibbonToggleButton(
          activeIcon: Icons.center_focus_strong,
          inactiveIcon: Icons.center_focus_weak,
          tooltip: 'Toggle Snap to Grid',
          isActive: snapToGrid,
          onPressed: onToggleSnapToGrid,
          compact: compact,
        ),
        ToolbarGridPresetMenu(
          selectedPreset: gridPreset,
          onSelected: onGridPresetSelected,
          compact: compact,
        ),
        RibbonToggleButton(
          activeIcon: Icons.speaker_notes,
          inactiveIcon: Icons.speaker_notes_off,
          tooltip: 'Toggle Speaker Notes',
          isActive: showSpeakerNotes,
          onPressed: onToggleSpeakerNotes,
          compact: compact,
        ),
      ],
    );
  }
}
