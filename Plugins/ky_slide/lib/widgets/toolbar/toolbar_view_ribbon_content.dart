import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/canvas_grid_preset.dart';
import 'ribbon_command_button.dart';
import 'ribbon_command_group.dart';
import 'toolbar_panel_visibility_group.dart';
import 'toolbar_responsive_layout.dart';
import 'toolbar_view_options_group.dart';

/// View ribbon tab content for canvas aids and editor panel visibility.
class ToolbarViewRibbonContent extends StatelessWidget {
  final bool showRuler;
  final bool showGrid;
  final bool snapToGrid;
  final CanvasGridPreset gridPreset;
  final bool showSpeakerNotes;
  final bool showSlideNavigator;
  final bool showInspector;
  final VoidCallback onToggleRuler;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnapToGrid;
  final ValueChanged<CanvasGridPreset> onGridPresetSelected;
  final VoidCallback onToggleSpeakerNotes;
  final VoidCallback onToggleSlideNavigator;
  final VoidCallback onToggleInspector;
  final VoidCallback onOpenSlideSorter;

  const ToolbarViewRibbonContent({
    super.key,
    required this.showRuler,
    required this.showGrid,
    required this.snapToGrid,
    required this.gridPreset,
    required this.showSpeakerNotes,
    required this.showSlideNavigator,
    required this.showInspector,
    required this.onToggleRuler,
    required this.onToggleGrid,
    required this.onToggleSnapToGrid,
    required this.onGridPresetSelected,
    required this.onToggleSpeakerNotes,
    required this.onToggleSlideNavigator,
    required this.onToggleInspector,
    required this.onOpenSlideSorter,
  });

  @override
  Widget build(BuildContext context) {
    return ToolbarResponsiveLayout(
      leadingGroup: (context, compact) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonCommandGroup(
            label: 'Show',
            child: ToolbarViewOptionsGroup(
              compact: true,
              showRuler: showRuler,
              showGrid: showGrid,
              snapToGrid: snapToGrid,
              gridPreset: gridPreset,
              showSpeakerNotes: showSpeakerNotes,
              onToggleRuler: onToggleRuler,
              onToggleGrid: onToggleGrid,
              onToggleSnapToGrid: onToggleSnapToGrid,
              onGridPresetSelected: onGridPresetSelected,
              onToggleSpeakerNotes: onToggleSpeakerNotes,
            ),
          ),
          RibbonCommandGroup(
            label: 'Panels',
            child: ToolbarPanelVisibilityGroup(
              compact: true,
              showSlideNavigator: showSlideNavigator,
              showInspector: showInspector,
              onToggleSlideNavigator: onToggleSlideNavigator,
              onToggleInspector: onToggleInspector,
            ),
          ),
          RibbonCommandGroup(
            label: 'Views',
            child: RibbonCommandButton(
              icon: Icons.view_module_outlined,
              label: 'Board',
              tooltip: 'Open Slide Sorter',
              onPressed: onOpenSlideSorter,
              compact: true,
            ),
          ),
        ],
      ),
      trailingGroups: (context, compact) => const [],
    );
  }
}

@Preview(name: 'Toolbar view ribbon content', size: Size(620, 88))
Widget toolbarViewRibbonContentPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          height: 78,
          child: ToolbarViewRibbonContent(
            showRuler: true,
            showGrid: false,
            snapToGrid: true,
            gridPreset: CanvasGridPreset.comfortable,
            showSpeakerNotes: true,
            showSlideNavigator: true,
            showInspector: true,
            onToggleRuler: () {},
            onToggleGrid: () {},
            onToggleSnapToGrid: () {},
            onGridPresetSelected: (_) {},
            onToggleSpeakerNotes: () {},
            onToggleSlideNavigator: () {},
            onToggleInspector: () {},
            onOpenSlideSorter: () {},
          ),
        ),
      ),
    ),
  );
}
