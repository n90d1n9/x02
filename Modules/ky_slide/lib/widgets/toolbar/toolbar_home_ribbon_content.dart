import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component_arrange_action.dart';
import '../../models/enums.dart';
import '../../models/slide_layout.dart';
import '../../services/slide_layout_service.dart';
import 'ribbon_command_group.dart';
import 'toolbar_layout_gallery.dart';
import 'toolbar_primary_tools_group.dart';
import 'toolbar_responsive_layout.dart';
import 'toolbar_selection_actions_group.dart';
import 'toolbar_slide_actions_group.dart';

/// Home ribbon tab content for slide, layout, tool, and arrange commands.
class ToolbarHomeRibbonContent extends StatelessWidget {
  final ToolMode currentTool;
  final bool canDeleteSlide;
  final bool hasSelection;
  final Color layoutAccentColor;
  final VoidCallback onAddSlide;
  final VoidCallback onDuplicateSlide;
  final VoidCallback onDeleteSlide;
  final ValueChanged<SlideLayoutType> onCreateLayout;
  final VoidCallback onSelectTool;
  final VoidCallback onTextTool;
  final ValueChanged<ComponentArrangeAction> onArrangeSelected;
  final VoidCallback onDeleteSelected;

  const ToolbarHomeRibbonContent({
    super.key,
    required this.currentTool,
    required this.canDeleteSlide,
    required this.hasSelection,
    required this.layoutAccentColor,
    required this.onAddSlide,
    required this.onDuplicateSlide,
    required this.onDeleteSlide,
    required this.onCreateLayout,
    required this.onSelectTool,
    required this.onTextTool,
    required this.onArrangeSelected,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ToolbarResponsiveLayout(
      leadingGroup: (context, compact) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonCommandGroup(
            label: 'Slides',
            child: ToolbarSlideActionsGroup(
              compact: true,
              canDeleteSlide: canDeleteSlide,
              onAddSlide: onAddSlide,
              onDuplicateSlide: onDuplicateSlide,
              onDeleteSlide: onDeleteSlide,
            ),
          ),
          RibbonCommandGroup(
            label: 'Layouts',
            child: ToolbarLayoutGallery(
              compact: compact,
              layouts: SlideLayoutService.recipes,
              accentColor: layoutAccentColor,
              onCreateLayout: onCreateLayout,
            ),
          ),
          RibbonCommandGroup(
            label: 'Tools',
            child: ToolbarPrimaryToolsGroup(
              compact: true,
              currentTool: currentTool,
              onSelectTool: onSelectTool,
              onTextTool: onTextTool,
            ),
          ),
          RibbonCommandGroup(
            label: 'Arrange',
            child: ToolbarSelectionActionsGroup(
              compact: true,
              hasSelection: hasSelection,
              onArrangeSelected: onArrangeSelected,
              onDeleteSelected: onDeleteSelected,
            ),
          ),
        ],
      ),
      trailingGroups: (context, compact) => const [],
    );
  }
}

@Preview(name: 'Toolbar home ribbon content', size: Size(760, 88))
Widget toolbarHomeRibbonContentPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          height: 78,
          child: ToolbarHomeRibbonContent(
            currentTool: ToolMode.select,
            canDeleteSlide: true,
            hasSelection: true,
            layoutAccentColor: const Color(0xFF38BDF8),
            onAddSlide: () {},
            onDuplicateSlide: () {},
            onDeleteSlide: () {},
            onCreateLayout: (_) {},
            onSelectTool: () {},
            onTextTool: () {},
            onArrangeSelected: (_) {},
            onDeleteSelected: () {},
          ),
        ),
      ),
    ),
  );
}
