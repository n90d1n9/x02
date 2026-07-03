import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/editor_deck_insight.dart';

/// Responsive deck identity shown in the editor top bar.
class EditorTopBarTitle extends StatelessWidget {
  final String title;
  final int slideIndex;
  final int slideCount;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> paletteColors;
  final EditorDeckInsight? deckInsight;

  const EditorTopBarTitle({
    super.key,
    required this.title,
    required this.slideIndex,
    required this.slideCount,
    required this.primaryColor,
    required this.secondaryColor,
    this.paletteColors = const [],
    this.deckInsight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSlideChip = constraints.maxWidth >= 300;
        final showPalette = constraints.maxWidth >= 420;
        final showDeckInsight = constraints.maxWidth >= 560;

        return Row(
          children: [
            _EditorPresentationMark(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (showPalette && paletteColors.isNotEmpty) ...[
              const SizedBox(width: 10),
              EditorThemePaletteStrip(colors: paletteColors),
            ],
            if (showSlideChip) ...[
              const SizedBox(width: 12),
              _EditorSlideProgressChip(
                slideIndex: slideIndex,
                slideCount: slideCount,
                accentColor: primaryColor,
              ),
            ],
            if (showDeckInsight && deckInsight != null) ...[
              const SizedBox(width: 10),
              EditorDeckInsightPill(
                insight: deckInsight!,
                accentColor: secondaryColor,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact deck metadata pill for the editor top bar.
class EditorDeckInsightPill extends StatelessWidget {
  final EditorDeckInsight insight;
  final Color accentColor;

  const EditorDeckInsightPill({
    super.key,
    required this.insight,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Deck insight: ${insight.tooltipLabel}',
      child: Semantics(
        label: 'Deck insight',
        value: insight.tooltipLabel,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, size: 14, color: accentColor),
              const SizedBox(width: 6),
              _DeckInsightMetric(label: insight.objectLabel),
              const _DeckInsightDivider(),
              _DeckInsightMetric(label: insight.notesLabel),
              const _DeckInsightDivider(),
              _DeckInsightMetric(label: insight.aspectRatioLabel),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single text metric used inside the deck insight pill.
class _DeckInsightMetric extends StatelessWidget {
  final String label;

  const _DeckInsightMetric({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

/// Visual separator between deck insight metrics.
class _DeckInsightDivider extends StatelessWidget {
  const _DeckInsightDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Compact color swatches that summarize the active presentation theme.
class EditorThemePaletteStrip extends StatelessWidget {
  final List<Color> colors;
  final int maxVisibleColors;

  const EditorThemePaletteStrip({
    super.key,
    required this.colors,
    this.maxVisibleColors = 4,
  });

  @override
  Widget build(BuildContext context) {
    final visibleColors = colors.take(maxVisibleColors).toList();

    return Tooltip(
      message: 'Theme palette',
      child: Semantics(
        label: 'Theme palette',
        value: '${visibleColors.length} colors',
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final indexedColor in visibleColors.indexed)
                Padding(
                  padding: EdgeInsets.only(left: indexedColor.$1 == 0 ? 0 : 3),
                  child: _ThemePaletteDot(color: indexedColor.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single swatch dot used by the top-bar theme palette strip.
class _ThemePaletteDot extends StatelessWidget {
  final Color color;

  const _ThemePaletteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Subtle action rail for related editor top-bar commands.
class EditorTopBarCommandGroup extends StatelessWidget {
  final List<Widget> children;

  const EditorTopBarCommandGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Icon command button used in the editor top bar.
class EditorTopBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const EditorTopBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      color: Colors.white70,
      disabledColor: Colors.white24,
      hoverColor: Colors.white.withValues(alpha: 0.08),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}

/// Primary action for entering presenter mode from the editor top bar.
class EditorPresentActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditorPresentActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Present (F5)',
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Present'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// Gradient product mark for deck identity.
class _EditorPresentationMark extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _EditorPresentationMark({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.slideshow, color: Colors.white, size: 20),
    );
  }
}

/// Compact slide progress badge for the current deck.
class _EditorSlideProgressChip extends StatelessWidget {
  final int slideIndex;
  final int slideCount;
  final Color accentColor;

  const _EditorSlideProgressChip({
    required this.slideIndex,
    required this.slideCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Slide ${slideIndex + 1}/$slideCount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accentColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

@Preview(name: 'Editor top bar title', size: Size(520, 90))
Widget editorTopBarTitlePreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 460,
          child: EditorTopBarTitle(
            title: 'Quarterly Business Review',
            slideIndex: 1,
            slideCount: 12,
            primaryColor: Color(0xFF38BDF8),
            secondaryColor: Color(0xFF22C55E),
            deckInsight: EditorDeckInsight(
              slideCount: 12,
              objectCount: 36,
              notesSlideCount: 4,
              themeName: 'Prism Studio',
              slideSize: Size(1920, 1080),
            ),
            paletteColors: [
              Color(0xFF38BDF8),
              Color(0xFF22C55E),
              Color(0xFFF59E0B),
              Color(0xFFEC4899),
            ],
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor deck insight pill', size: Size(280, 80))
Widget editorDeckInsightPillPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorDeckInsightPill(
          insight: EditorDeckInsight(
            slideCount: 12,
            objectCount: 36,
            notesSlideCount: 4,
            themeName: 'Prism Studio',
            slideSize: Size(1920, 1080),
          ),
          accentColor: Color(0xFF22C55E),
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor theme palette strip', size: Size(180, 80))
Widget editorThemePaletteStripPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorThemePaletteStrip(
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF22C55E),
            Color(0xFFF59E0B),
            Color(0xFFEC4899),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor top bar commands', size: Size(360, 90))
Widget editorTopBarCommandsPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorTopBarCommandGroup(
              children: [
                EditorTopBarIconButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: () {},
                ),
                EditorTopBarIconButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: null,
                ),
                EditorTopBarIconButton(
                  icon: Icons.folder_open_outlined,
                  tooltip: 'Import / Export',
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(width: 8),
            EditorPresentActionButton(onPressed: () {}),
          ],
        ),
      ),
    ),
  );
}
