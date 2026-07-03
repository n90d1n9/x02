import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ribbon_command_button.dart';

/// Ribbon group for inserting external media objects.
class ToolbarInsertGroup extends StatelessWidget {
  final VoidCallback onImage;
  final VoidCallback onVideo;
  final bool compact;

  const ToolbarInsertGroup({
    super.key,
    required this.onImage,
    required this.onVideo,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonCommandButton(
          icon: Icons.image,
          label: 'Image',
          tooltip: 'Insert Image',
          onPressed: onImage,
          compact: compact,
        ),
        RibbonCommandButton(
          icon: Icons.videocam,
          label: 'Video',
          tooltip: 'Insert Video',
          onPressed: onVideo,
          compact: compact,
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar insert group', size: Size(180, 96))
Widget toolbarInsertGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarInsertGroup(onImage: () {}, onVideo: () {}),
      ),
    ),
  );
}
