import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/editor_slide_jump_summary.dart';
import 'editor_status_bar_widgets.dart';

/// Tiny status-bar progress meter showing the current slide position.
class EditorSlideProgressMeter extends StatelessWidget {
  final int currentSlideIndex;
  final int slideCount;
  final Color accentColor;

  const EditorSlideProgressMeter({
    super.key,
    required this.currentSlideIndex,
    required this.slideCount,
    this.accentColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    final safeSlideCount = slideCount <= 0 ? 1 : slideCount;
    final safeCurrentIndex = currentSlideIndex.clamp(0, safeSlideCount - 1);
    final progress = ((safeCurrentIndex + 1) / safeSlideCount).clamp(0, 1);

    return Tooltip(
      message: 'Slide position',
      child: Semantics(
        label: 'Slide position',
        value: 'Slide ${safeCurrentIndex + 1} of $safeSlideCount',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact previous/next slide control for the editor status bar.
class EditorStatusSlideNavigator extends StatelessWidget {
  final int currentSlideIndex;
  final int slideCount;
  final List<String> slideTitles;
  final List<EditorSlideJumpSummary> slideSummaries;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int>? onSlideSelected;

  const EditorStatusSlideNavigator({
    super.key,
    required this.currentSlideIndex,
    required this.slideCount,
    this.slideTitles = const [],
    this.slideSummaries = const [],
    this.onPrevious,
    this.onNext,
    this.onSlideSelected,
  });

  @override
  Widget build(BuildContext context) {
    final safeSlideCount = slideCount <= 0 ? 1 : slideCount;
    final safeCurrentIndex = currentSlideIndex.clamp(0, safeSlideCount - 1);
    final canGoPrevious = safeCurrentIndex > 0;
    final canGoNext = safeCurrentIndex < safeSlideCount - 1;
    final canJump = onSlideSelected != null && safeSlideCount > 1;
    final slideLabel = 'Slide ${safeCurrentIndex + 1} of $safeSlideCount';

    return Semantics(
      label: slideLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SlideStepButton(
            tooltip: 'Previous slide',
            icon: Icons.keyboard_arrow_left,
            onPressed: canGoPrevious ? onPrevious : null,
          ),
          _SlideJumpLabel(
            label: slideLabel,
            selectedIndex: safeCurrentIndex,
            slideCount: safeSlideCount,
            slideTitles: slideTitles,
            slideSummaries: slideSummaries,
            onSlideSelected: canJump ? onSlideSelected : null,
          ),
          _SlideStepButton(
            tooltip: 'Next slide',
            icon: Icons.keyboard_arrow_right,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Clickable slide counter that opens a compact jump-to-slide menu.
class _SlideJumpLabel extends StatelessWidget {
  final String label;
  final int selectedIndex;
  final int slideCount;
  final List<String> slideTitles;
  final List<EditorSlideJumpSummary> slideSummaries;
  final ValueChanged<int>? onSlideSelected;

  const _SlideJumpLabel({
    required this.label,
    required this.selectedIndex,
    required this.slideCount,
    required this.slideTitles,
    required this.slideSummaries,
    required this.onSlideSelected,
  });

  @override
  Widget build(BuildContext context) {
    final child = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 86, maxWidth: 126),
      child: SizedBox(
        height: 28,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: EditorStatusText(
                      label,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onSlideSelected != null) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.expand_less,
                      size: 13,
                      color: Colors.white54,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              EditorSlideProgressMeter(
                currentSlideIndex: selectedIndex,
                slideCount: slideCount,
              ),
            ],
          ),
        ),
      ),
    );

    if (onSlideSelected == null) return child;

    return PopupMenuButton<int>(
      tooltip: 'Jump to slide',
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, -8),
      onSelected: onSlideSelected,
      itemBuilder: (context) {
        return <PopupMenuEntry<int>>[
          PopupMenuItem<int>(
            enabled: false,
            child: EditorSlideJumpMenuHeader(
              currentSlideIndex: selectedIndex,
              slideCount: slideCount,
            ),
          ),
          const PopupMenuDivider(height: 1),
          ...List.generate(slideCount, (index) {
            return PopupMenuItem<int>(
              value: index,
              child: EditorSlideJumpMenuItem(
                summary: _summaryFor(index),
                isSelected: index == selectedIndex,
              ),
            );
          }),
        ];
      },
      child: child,
    );
  }

  String _titleFor(int index) {
    if (index < 0 || index >= slideTitles.length) {
      return 'Slide ${index + 1}';
    }

    final title = slideTitles[index].trim();
    return title.isEmpty ? 'Slide ${index + 1}' : title;
  }

  EditorSlideJumpSummary _summaryFor(int index) {
    if (index >= 0 && index < slideSummaries.length) {
      return slideSummaries[index];
    }

    return EditorSlideJumpSummary(index: index, title: _titleFor(index));
  }
}

/// Compact summary header shown above status-bar slide jump rows.
class EditorSlideJumpMenuHeader extends StatelessWidget {
  final int currentSlideIndex;
  final int slideCount;
  final Color accentColor;

  const EditorSlideJumpMenuHeader({
    super.key,
    required this.currentSlideIndex,
    required this.slideCount,
    this.accentColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    final safeSlideCount = slideCount <= 0 ? 1 : slideCount;
    final safeCurrentIndex = currentSlideIndex.clamp(0, safeSlideCount - 1);
    final slideWord = safeSlideCount == 1 ? 'slide' : 'slides';

    return Semantics(
      label: 'Slide jump menu summary',
      value: 'Slide ${safeCurrentIndex + 1} of $safeSlideCount',
      child: SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.slideshow_outlined,
                    size: 15,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Jump to slide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$safeSlideCount $slideWord',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EditorSlideProgressMeter(
              currentSlideIndex: safeCurrentIndex,
              slideCount: safeSlideCount,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single row in the status-bar slide jump popup.
class EditorSlideJumpMenuItem extends StatelessWidget {
  final EditorSlideJumpSummary summary;
  final bool isSelected;

  const EditorSlideJumpMenuItem({
    super.key,
    required this.summary,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 26,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.44)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Center(
              child: Text(
                '${summary.index + 1}',
                style: TextStyle(
                  color: isSelected ? const Color(0xFFBAE6FD) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                _SlideJumpMetadataRow(summary: summary),
              ],
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.check, size: 16, color: Color(0xFF38BDF8)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Secondary metadata line for a slide jump menu item.
class _SlideJumpMetadataRow extends StatelessWidget {
  final EditorSlideJumpSummary summary;

  const _SlideJumpMetadataRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final objectLabel = summary.objectLabel;

    return Row(
      children: [
        if (objectLabel != null)
          Flexible(
            child: Text(
              objectLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        if (objectLabel != null && summary.hasSpeakerNotes)
          const SizedBox(width: 6),
        if (summary.hasSpeakerNotes)
          const _SlideJumpMetadataPill(
            icon: Icons.speaker_notes_outlined,
            label: 'Notes',
          ),
      ],
    );
  }
}

/// Small inline badge used for slide jump metadata.
class _SlideJumpMetadataPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SlideJumpMetadataPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white54),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon command used by the status-bar slide navigator.
class _SlideStepButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SlideStepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? Colors.white60 : Colors.white24;

    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      color: color,
      disabledColor: color,
      hoverColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 26, height: 28),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      onPressed: onPressed,
    );
  }
}

@Preview(name: 'Editor status slide navigator', size: Size(220, 80))
Widget editorStatusSlideNavigatorPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorStatusControlGroup(
          children: [
            EditorStatusSlideNavigator(
              currentSlideIndex: 2,
              slideCount: 12,
              slideTitles: const [
                'Intro',
                'Market',
                'Roadmap',
                'Launch',
                'Appendix',
              ],
              onPrevious: () {},
              onNext: () {},
              onSlideSelected: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor slide progress meter', size: Size(180, 70))
Widget editorSlideProgressMeterPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 120,
          child: EditorSlideProgressMeter(currentSlideIndex: 4, slideCount: 12),
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor slide jump menu header', size: Size(260, 120))
Widget editorSlideJumpMenuHeaderPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorSlideJumpMenuHeader(currentSlideIndex: 3, slideCount: 12),
      ),
    ),
  );
}

@Preview(name: 'Editor slide jump menu item', size: Size(300, 100))
Widget editorSlideJumpMenuItemPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF111827)),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: EditorSlideJumpMenuItem(
              summary: EditorSlideJumpSummary(
                index: 2,
                title: 'Revenue model',
                objectCount: 6,
                hasSpeakerNotes: true,
              ),
              isSelected: true,
            ),
          ),
        ),
      ),
    ),
  );
}
