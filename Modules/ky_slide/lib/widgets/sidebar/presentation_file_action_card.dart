import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/presentation_file_format.dart';
import 'sidebar_action_card.dart';
import 'sidebar_metadata_pill.dart';

/// Action card for a single import or export capability in the file panel.
class PresentationFileActionCard extends StatelessWidget {
  final PresentationFileCapability capability;
  final Color accentColor;
  final VoidCallback onPressed;

  const PresentationFileActionCard({
    super.key,
    required this.capability,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(capability.support);

    return SidebarActionCard(
      semanticsLabel: capability.title,
      accentColor: statusColor,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(_formatIcon, color: statusColor, size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  capability.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SidebarMetadataPill(
                icon: _statusIcon(capability.support),
                label: capability.support.label,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            capability.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '.${capability.format.extension}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                capability.actionLabel,
                style: TextStyle(
                  color: capability.isNative ? accentColor : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                color: capability.isNative ? accentColor : Colors.white54,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _formatIcon {
    switch (capability.format) {
      case PresentationFileFormat.pptx:
      case PresentationFileFormat.ppt:
        return Icons.slideshow_outlined;
      case PresentationFileFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  Color _statusColor(PresentationFileSupport support) {
    switch (support) {
      case PresentationFileSupport.native:
        return accentColor;
      case PresentationFileSupport.converterRequired:
        return const Color(0xFFF59E0B);
      case PresentationFileSupport.planned:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _statusIcon(PresentationFileSupport support) {
    switch (support) {
      case PresentationFileSupport.native:
        return Icons.check_circle_outline;
      case PresentationFileSupport.converterRequired:
        return Icons.sync_alt_outlined;
      case PresentationFileSupport.planned:
        return Icons.schedule_outlined;
    }
  }
}

@Preview(name: 'Presentation file action card', size: Size(320, 150))
Widget presentationFileActionCardPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 280,
          child: PresentationFileActionCard(
            capability: const PresentationFileCapability(
              format: PresentationFileFormat.pptx,
              operation: PresentationFileOperation.export,
              support: PresentationFileSupport.native,
              title: 'Export PPTX',
              description: 'Native OpenXML export for editor handoff.',
              actionLabel: 'Export',
            ),
            accentColor: const Color(0xFF22C55E),
            onPressed: () {},
          ),
        ),
      ),
    ),
  );
}
