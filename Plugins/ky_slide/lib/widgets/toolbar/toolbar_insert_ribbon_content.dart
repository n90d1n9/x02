import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/enums.dart';
import 'ribbon_command_group.dart';
import 'toolbar_chart_gallery.dart';
import 'toolbar_insert_group.dart';
import 'toolbar_interactive_gallery.dart';
import 'toolbar_responsive_layout.dart';
import 'toolbar_shape_gallery.dart';

/// Insert ribbon tab content for media, charts, shapes, and interactive objects.
class ToolbarInsertRibbonContent extends StatelessWidget {
  final List<Color> palette;
  final Color accentColor;
  final Color secondaryColor;
  final VoidCallback onImage;
  final VoidCallback onVideo;
  final ValueChanged<ChartType> onCreateChart;
  final ValueChanged<ComponentType> onCreateShape;
  final ValueChanged<InteractiveType> onCreateInteractive;

  const ToolbarInsertRibbonContent({
    super.key,
    required this.palette,
    required this.accentColor,
    required this.secondaryColor,
    required this.onImage,
    required this.onVideo,
    required this.onCreateChart,
    required this.onCreateShape,
    required this.onCreateInteractive,
  });

  @override
  Widget build(BuildContext context) {
    return ToolbarResponsiveLayout(
      leadingGroup: (context, compact) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RibbonCommandGroup(
            label: 'Objects',
            child: ToolbarInsertGroup(
              compact: true,
              onImage: onImage,
              onVideo: onVideo,
            ),
          ),
          RibbonCommandGroup(
            label: 'Charts',
            child: ToolbarChartGallery(
              compact: compact,
              palette: palette,
              onCreateChart: onCreateChart,
            ),
          ),
          RibbonCommandGroup(
            label: 'Shapes',
            child: ToolbarShapeGallery(
              compact: compact,
              accentColor: accentColor,
              secondaryColor: secondaryColor,
              onCreateShape: onCreateShape,
            ),
          ),
          RibbonCommandGroup(
            label: 'Interactive',
            child: ToolbarInteractiveGallery(
              compact: compact,
              accentColor: accentColor,
              secondaryColor: secondaryColor,
              onCreateInteractive: onCreateInteractive,
            ),
          ),
        ],
      ),
      trailingGroups: (context, compact) => const [],
    );
  }
}

@Preview(name: 'Toolbar insert ribbon content', size: Size(760, 88))
Widget toolbarInsertRibbonContentPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          height: 78,
          child: ToolbarInsertRibbonContent(
            palette: const [Color(0xFF38BDF8), Color(0xFF22C55E)],
            accentColor: const Color(0xFF38BDF8),
            secondaryColor: const Color(0xFF22C55E),
            onImage: () {},
            onVideo: () {},
            onCreateChart: (_) {},
            onCreateShape: (_) {},
            onCreateInteractive: (_) {},
          ),
        ),
      ),
    ),
  );
}
