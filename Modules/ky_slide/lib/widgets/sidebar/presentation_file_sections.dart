import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/presentation_file_format.dart';
import 'presentation_file_action_card.dart';
import 'sidebar_metadata_pill.dart';

/// Compact deck summary for the import/export sidebar workspace.
class PresentationFileSummaryCard extends StatelessWidget {
  final int slideCount;
  final String title;
  final Size slideSize;
  final Color accentColor;

  const PresentationFileSummaryCard({
    super.key,
    required this.slideCount,
    required this.title,
    required this.slideSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: accentColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SidebarMetadataPill(
                      icon: Icons.slideshow_outlined,
                      label: '$slideCount slide${slideCount == 1 ? '' : 's'}',
                      color: accentColor,
                    ),
                    SidebarMetadataPill(
                      icon: Icons.aspect_ratio_outlined,
                      label: _aspectLabel,
                      color: Colors.white60,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _aspectLabel {
    final ratio = slideSize.width / slideSize.height;
    if ((ratio - 16 / 9).abs() <= 0.02) return '16:9';
    if ((ratio - 4 / 3).abs() <= 0.02) return '4:3';

    return '${slideSize.width.round()}x${slideSize.height.round()}';
  }
}

/// Labeled group for related presentation file import or export actions.
class PresentationFileCapabilityGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final List<PresentationFileCapability> capabilities;
  final ValueChanged<PresentationFileCapability> onSelected;

  const PresentationFileCapabilityGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.accentColor,
    required this.capabilities,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PresentationFileGroupLabel(icon: icon, label: title, color: color),
        const SizedBox(height: 8),
        ...capabilities.map(
          (capability) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PresentationFileActionCard(
              capability: capability,
              accentColor: accentColor,
              onPressed: () => onSelected(capability),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section label used by file capability groups.
class _PresentationFileGroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PresentationFileGroupLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Presentation file summary card', size: Size(340, 120))
Widget presentationFileSummaryCardPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 300,
          child: PresentationFileSummaryCard(
            title: 'Quarterly Business Review',
            slideCount: 12,
            slideSize: Size(1920, 1080),
            accentColor: Color(0xFF38BDF8),
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Presentation file capability group', size: Size(360, 300))
Widget presentationFileCapabilityGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 300,
          child: PresentationFileCapabilityGroup(
            title: 'Export',
            icon: Icons.file_download_outlined,
            color: const Color(0xFF22C55E),
            accentColor: const Color(0xFF22C55E),
            capabilities: const [
              PresentationFileCapability(
                format: PresentationFileFormat.pptx,
                operation: PresentationFileOperation.export,
                support: PresentationFileSupport.native,
                title: 'Export PPTX',
                description: 'Native OpenXML export for editor handoff.',
                actionLabel: 'Export',
              ),
              PresentationFileCapability(
                format: PresentationFileFormat.pdf,
                operation: PresentationFileOperation.export,
                support: PresentationFileSupport.planned,
                title: 'Export PDF',
                description: 'Print-ready static export for review.',
                actionLabel: 'Export',
              ),
            ],
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}
