import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/sidebar_menu_item.dart';
import '../../models/slide_template.dart';
import '../../services/slide_template_service.dart';
import 'ribbon_command_group.dart';
import 'toolbar_responsive_layout.dart';
import 'toolbar_sidebar_panels_group.dart';
import 'toolbar_template_gallery.dart';

/// Design ribbon tab content for templates and sidebar panel shortcuts.
class ToolbarDesignRibbonContent extends StatelessWidget {
  final List<Color> palette;
  final Color secondaryColor;
  final ValueChanged<SlideTemplateType> onCreateTemplate;
  final ValueChanged<SidebarMenuItem> onOpenPanel;

  const ToolbarDesignRibbonContent({
    super.key,
    required this.palette,
    required this.secondaryColor,
    required this.onCreateTemplate,
    required this.onOpenPanel,
  });

  @override
  Widget build(BuildContext context) {
    return ToolbarResponsiveLayout(
      leadingGroup: (context, compact) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonCommandGroup(
            label: 'Templates',
            child: ToolbarTemplateGallery(
              compact: compact,
              templates: SlideTemplateService.recipes,
              palette: palette,
              secondaryColor: secondaryColor,
              onCreateTemplate: onCreateTemplate,
            ),
          ),
          RibbonCommandGroup(
            label: 'Panels',
            child: ToolbarSidebarPanelsGroup(
              compact: compact,
              onOpenPanel: onOpenPanel,
            ),
          ),
        ],
      ),
      trailingGroups: (context, compact) => const [],
    );
  }
}

@Preview(name: 'Toolbar design ribbon content', size: Size(660, 88))
Widget toolbarDesignRibbonContentPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          height: 78,
          child: ToolbarDesignRibbonContent(
            palette: const [Color(0xFF38BDF8), Color(0xFF22C55E)],
            secondaryColor: const Color(0xFF22C55E),
            onCreateTemplate: (_) {},
            onOpenPanel: (_) {},
          ),
        ),
      ),
    ),
  );
}
