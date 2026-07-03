import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Shared visual shell for compact ribbon gallery entries.
class ToolbarGalleryTile extends StatelessWidget {
  final String label;
  final String tooltip;
  final Widget preview;
  final VoidCallback onPressed;
  final Color borderColor;
  final bool compact;
  final double compactWidth;
  final double width;
  final double compactPreviewWidth;
  final double previewWidth;

  const ToolbarGalleryTile({
    super.key,
    required this.label,
    required this.tooltip,
    required this.preview,
    required this.onPressed,
    required this.borderColor,
    this.compact = false,
    this.compactWidth = 70,
    this.width = 78,
    this.compactPreviewWidth = 44,
    this.previewWidth = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: compact ? compactWidth : width,
              height: 50,
              padding: const EdgeInsets.fromLTRB(5, 2, 5, 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? compactPreviewWidth : previewWidth,
                    child: preview,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Toolbar gallery tile', size: Size(128, 96))
Widget toolbarGalleryTilePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: ToolbarGalleryTile(
          label: 'Sample',
          tooltip: 'Insert Sample',
          borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.32),
          preview: const Icon(Icons.view_carousel, color: Color(0xFF38BDF8)),
          onPressed: () {},
        ),
      ),
    ),
  );
}
