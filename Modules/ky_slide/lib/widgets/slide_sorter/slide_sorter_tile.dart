import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/rich_text_content.dart';
import '../../models/slide.dart';
import '../../models/style/presentation_theme.dart';
import '../sidebar/slide_thumbnail_preview.dart';

/// Visual board tile for reviewing, selecting, and managing one slide.
class SlideSorterTile extends StatelessWidget {
  final Slide slide;
  final int index;
  final bool isSelected;
  final bool isBatchSelected;
  final PresentationTheme theme;
  final Size slideSize;
  final bool canDelete;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggleSelection;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;

  const SlideSorterTile({
    super.key,
    required this.slide,
    required this.index,
    required this.isSelected,
    required this.isBatchSelected,
    required this.theme,
    required this.slideSize,
    required this.canDelete,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onSelect,
    required this.onToggleSelection,
    required this.onDuplicate,
    required this.onDelete,
    this.onMoveEarlier,
    this.onMoveLater,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.primaryColor;
    final title = _slideTitle;
    final borderColor = isSelected
        ? accentColor.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.08);

    return Semantics(
      button: true,
      selected: isSelected,
      checked: isBatchSelected,
      label: 'Slide ${index + 1}: $title, ${slide.components.length} objects',
      child: Tooltip(
        message: 'Open slide ${index + 1}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SlideSorterTileHeader(
                    index: index,
                    title: title,
                    isSelected: isSelected,
                    isBatchSelected: isBatchSelected,
                    accentColor: accentColor,
                    onToggleSelection: onToggleSelection,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: SlideThumbnailPreview(
                              slide: slide,
                              theme: theme,
                              slideSize: slideSize,
                              maxVisibleComponents: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: _SlideMetricPill(
                            icon: Icons.layers_outlined,
                            label: '${slide.components.length}',
                            accentColor: accentColor,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _SlideMetricPill(
                            icon: Icons.slideshow_outlined,
                            label: slide.transition.name,
                            accentColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  _SlideSorterActionRow(
                    index: index,
                    canDelete: canDelete,
                    canMoveEarlier: canMoveEarlier,
                    canMoveLater: canMoveLater,
                    onDuplicate: onDuplicate,
                    onDelete: onDelete,
                    onMoveEarlier: onMoveEarlier,
                    onMoveLater: onMoveLater,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _slideTitle {
    final title = slide.title?.trim();
    if (title == null || title.isEmpty) return 'Slide ${index + 1}';
    return title;
  }
}

/// Header area for slide number, title, selection state, and drag affordance.
class _SlideSorterTileHeader extends StatelessWidget {
  final int index;
  final String title;
  final bool isSelected;
  final bool isBatchSelected;
  final Color accentColor;
  final ValueChanged<bool> onToggleSelection;

  const _SlideSorterTileHeader({
    required this.index,
    required this.title,
    required this.isSelected,
    required this.isBatchSelected,
    required this.accentColor,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.white38, size: 16),
          const SizedBox(width: 3),
          _SlideSelectionToggle(
            index: index,
            selected: isBatchSelected,
            accentColor: accentColor,
            onPressed: onToggleSelection,
          ),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.075),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: isSelected ? 1 : 0,
            child: Icon(Icons.check_circle, size: 17, color: accentColor),
          ),
        ],
      ),
    );
  }
}

/// Checkbox-style control for adding a slide to the batch selection.
class _SlideSelectionToggle extends StatelessWidget {
  final int index;
  final bool selected;
  final Color accentColor;
  final ValueChanged<bool> onPressed;

  const _SlideSelectionToggle({
    required this.index,
    required this.selected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        tooltip: selected
            ? 'Deselect slide ${index + 1}'
            : 'Select slide ${index + 1}',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        visualDensity: VisualDensity.compact,
        onPressed: () => onPressed(_rangeModifierPressed),
        icon: Icon(
          selected ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: selected ? accentColor : Colors.white54,
        ),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? accentColor.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.035),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(
              color: selected
                  ? accentColor.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
      ),
    );
  }

  bool get _rangeModifierPressed {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.shiftRight);
  }
}

/// Compact thumbnail overlay metric for object counts and transition labels.
class _SlideMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _SlideMetricPill({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action row for per-slide reorder, duplicate, and delete commands.
class _SlideSorterActionRow extends StatelessWidget {
  final int index;
  final bool canDelete;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;

  const _SlideSorterActionRow({
    required this.index,
    required this.canDelete,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onDuplicate,
    required this.onDelete,
    this.onMoveEarlier,
    this.onMoveLater,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _SorterIconAction(
            icon: Icons.arrow_back,
            tooltip: 'Move slide ${index + 1} earlier',
            onPressed: canMoveEarlier ? onMoveEarlier : null,
          ),
          const SizedBox(width: 5),
          _SorterIconAction(
            icon: Icons.arrow_forward,
            tooltip: 'Move slide ${index + 1} later',
            onPressed: canMoveLater ? onMoveLater : null,
          ),
          const Spacer(),
          _SorterIconAction(
            icon: Icons.content_copy_outlined,
            tooltip: 'Duplicate slide ${index + 1}',
            onPressed: onDuplicate,
          ),
          const SizedBox(width: 5),
          _SorterIconAction(
            icon: canDelete ? Icons.delete_outline : Icons.lock_outline,
            tooltip: canDelete
                ? 'Delete slide ${index + 1}'
                : 'Keep last slide',
            onPressed: canDelete ? onDelete : null,
            destructive: canDelete,
          ),
        ],
      ),
    );
  }
}

/// Small icon command button used by slide board tiles.
class _SorterIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool destructive;

  const _SorterIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = !enabled
        ? Colors.white24
        : destructive
        ? const Color(0xFFFCA5A5)
        : Colors.white70;

    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        iconSize: 16,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? Colors.white.withValues(alpha: 0.055)
              : Colors.white.withValues(alpha: 0.025),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Slide sorter tile', size: Size(280, 260))
Widget slideSorterTilePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 240,
          height: 230,
          child: SlideSorterTile(
            slide: _previewSlide(),
            index: 1,
            isSelected: true,
            isBatchSelected: true,
            theme: _previewTheme(),
            slideSize: const Size(1920, 1080),
            canDelete: true,
            canMoveEarlier: true,
            canMoveLater: true,
            onSelect: () {},
            onToggleSelection: (_) {},
            onDuplicate: () {},
            onDelete: () {},
            onMoveEarlier: () {},
            onMoveLater: () {},
          ),
        ),
      ),
    ),
  );
}

Slide _previewSlide() {
  return Slide(
    id: 'sorter-preview-slide',
    title: 'Market story',
    backgroundColor: const Color(0xFF111827),
    components: [
      PresentationComponent(
        id: 'title',
        type: ComponentType.richText,
        position: const Offset(170, 120),
        size: const Size(860, 150),
        zIndex: 1,
        richText: RichTextContent(
          text: 'Market story',
          style: const TextStyle(color: Colors.white, fontSize: 56),
        ),
      ),
      PresentationComponent(
        id: 'chart',
        type: ComponentType.chart,
        position: const Offset(980, 330),
        size: const Size(520, 360),
        zIndex: 2,
      ),
      PresentationComponent(
        id: 'shape',
        type: ComponentType.shape,
        position: const Offset(180, 420),
        size: const Size(560, 90),
        zIndex: 3,
        backgroundColor: const Color(0xFF14B8A6),
      ),
    ],
  );
}

PresentationTheme _previewTheme() {
  return PresentationTheme(
    id: 'sorter-preview-theme',
    name: 'Sorter Preview',
    primaryColor: const Color(0xFF38BDF8),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
    bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
    colorPalette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
  );
}
