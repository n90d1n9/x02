import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/speaker_notes_metrics.dart';

/// Provider-free speaker notes editor used by the presentation editor pane.
class SpeakerNotesEditor extends StatelessWidget {
  final int slideNumber;
  final String slideTitle;
  final SpeakerNotesMetrics metrics;
  final bool canClear;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const SpeakerNotesEditor({
    super.key,
    required this.slideNumber,
    required this.slideTitle,
    required this.metrics,
    required this.canClear,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          _SpeakerNotesHeader(
            slideNumber: slideNumber,
            slideTitle: slideTitle,
            metrics: metrics,
            canClear: canClear,
            onClear: onClear,
            onClose: onClose,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: null,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: 0,
                ),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Click to add speaker notes',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.035),
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact metadata and command rail for the speaker notes editor.
class _SpeakerNotesHeader extends StatelessWidget {
  final int slideNumber;
  final String slideTitle;
  final SpeakerNotesMetrics metrics;
  final bool canClear;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const _SpeakerNotesHeader({
    required this.slideNumber,
    required this.slideTitle,
    required this.metrics,
    required this.canClear,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final title = slideTitle.trim().isEmpty ? 'Untitled slide' : slideTitle;

    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.speaker_notes, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Speaker notes - Slide $slideNumber - $title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            SpeakerNotesMetricPill(label: metrics.wordLabel),
            const SizedBox(width: 6),
            SpeakerNotesMetricPill(label: metrics.characterLabel),
            const SizedBox(width: 6),
            SpeakerNotesMetricPill(label: metrics.speakingTimeLabel),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Clear speaker notes',
              icon: const Icon(Icons.backspace_outlined, size: 17),
              color: canClear ? Colors.white54 : Colors.white24,
              onPressed: canClear ? onClear : null,
            ),
            IconButton(
              tooltip: 'Hide speaker notes',
              icon: const Icon(Icons.close, size: 18),
              color: Colors.white54,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small count badge for speaker note metadata.
class SpeakerNotesMetricPill extends StatelessWidget {
  final String label;

  const SpeakerNotesMetricPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

@Preview(name: 'Speaker notes editor', size: Size(760, 180))
Widget speakerNotesEditorPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SpeakerNotesEditor(
          slideNumber: 3,
          slideTitle: 'Market expansion',
          metrics: SpeakerNotesMetrics.fromText(
            'Open with customer story\nPause before the metric.',
          ),
          canClear: true,
          controller: TextEditingController(
            text: 'Open with customer story\nPause before the metric.',
          ),
          focusNode: FocusNode(),
          onChanged: (_) {},
          onClear: () {},
          onClose: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Speaker notes metric pill', size: Size(140, 70))
Widget speakerNotesMetricPillPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: SpeakerNotesMetricPill(label: '<1 min talk')),
    ),
  );
}
