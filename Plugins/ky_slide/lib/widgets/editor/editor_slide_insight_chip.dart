import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/editor_slide_insight.dart';

/// Compact status-bar chip that summarizes the active slide's edit state.
class EditorSlideInsightChip extends StatelessWidget {
  final EditorSlideInsight insight;
  final Color accentColor;
  final bool compact;

  const EditorSlideInsightChip({
    super.key,
    required this.insight,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hiddenBadgeLabel = insight.hiddenBadgeLabel;
    final lockedBadgeLabel = insight.lockedBadgeLabel;
    final notesBadgeLabel = insight.notesBadgeLabel;
    final showBadges =
        !compact &&
        (hiddenBadgeLabel != null ||
            lockedBadgeLabel != null ||
            notesBadgeLabel != null);

    return Tooltip(
      message: 'Slide insight: ${insight.tooltipLabel}',
      child: Semantics(
        label: 'Slide insight',
        value: insight.tooltipLabel,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.26)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                insight.objectLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              if (showBadges) ...[
                const SizedBox(width: 7),
                if (hiddenBadgeLabel != null)
                  _SlideInsightBadge(
                    label: hiddenBadgeLabel,
                    icon: Icons.visibility_off_outlined,
                  ),
                if (lockedBadgeLabel != null)
                  _SlideInsightBadge(
                    label: lockedBadgeLabel,
                    icon: Icons.lock_outline,
                  ),
                if (notesBadgeLabel != null)
                  _SlideInsightBadge(
                    label: notesBadgeLabel,
                    icon: Icons.speaker_notes_outlined,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small optional badge used by the current-slide insight chip.
class _SlideInsightBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SlideInsightBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white60),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Editor slide insight chip', size: Size(300, 80))
Widget editorSlideInsightChipPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorSlideInsightChip(
          insight: EditorSlideInsight(
            objectCount: 8,
            hiddenObjectCount: 1,
            lockedObjectCount: 2,
            hasSpeakerNotes: true,
          ),
          accentColor: Color(0xFF38BDF8),
        ),
      ),
    ),
  );
}
