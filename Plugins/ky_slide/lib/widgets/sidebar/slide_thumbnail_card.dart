import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/rich_text_content.dart';
import '../../models/slide.dart';
import '../../models/slide_navigator_density.dart';
import '../../models/style/presentation_theme.dart';
import 'sidebar_action_card.dart';
import 'slide_thumbnail_preview.dart';
import 'slide_thumbnail_quick_actions.dart';

/// Reusable slide navigator card with thumbnail preview and quick actions.
class SlideThumbnailCard extends StatelessWidget {
  final Slide slide;
  final int index;
  final bool isSelected;
  final PresentationTheme theme;
  final Size slideSize;
  final SlideNavigatorDensity density;
  final VoidCallback onSelect;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final bool canDelete;
  final VoidCallback? onDeleteUnavailable;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;

  const SlideThumbnailCard({
    super.key,
    required this.slide,
    required this.index,
    required this.isSelected,
    required this.theme,
    required this.slideSize,
    this.density = SlideNavigatorDensity.comfortable,
    required this.onSelect,
    required this.onDuplicate,
    required this.onDelete,
    this.canDelete = true,
    this.onDeleteUnavailable,
    this.onMoveUp,
    this.onMoveDown,
    this.canMoveUp = false,
    this.canMoveDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.primaryColor;
    final title = slide.title ?? 'Slide ${index + 1}';

    return SidebarActionCard(
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: density.cardVerticalMargin,
      ),
      accentColor: accentColor,
      selected: isSelected,
      onPressed: onSelect,
      animationDuration: const Duration(milliseconds: 160),
      semanticsLabel: 'Select slide ${index + 1}: $title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideCardHeader(
            index: index,
            title: title,
            isSelected: isSelected,
            theme: theme,
            onDuplicate: onDuplicate,
            onDelete: onDelete,
            canDelete: canDelete,
            onDeleteUnavailable: onDeleteUnavailable,
          ),
          SizedBox(height: density.headerGap),
          SizedBox(
            height: density.previewHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SlideThumbnailPreview(
                    slide: slide,
                    theme: theme,
                    slideSize: slideSize,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 7,
                  child: _ComponentCountBadge(
                    count: slide.components.length,
                    accentColor: accentColor,
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: SlideThumbnailQuickActions(
                    accentColor: accentColor,
                    canMoveUp: canMoveUp,
                    canMoveDown: canMoveDown,
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown,
                    onDuplicate: onDuplicate,
                    onDelete: onDelete,
                    canDelete: canDelete,
                    onDeleteUnavailable: onDeleteUnavailable,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCardHeader extends StatelessWidget {
  final int index;
  final String title;
  final bool isSelected;
  final PresentationTheme theme;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final bool canDelete;
  final VoidCallback? onDeleteUnavailable;

  const _SlideCardHeader({
    required this.index,
    required this.title,
    required this.isSelected,
    required this.theme,
    required this.onDuplicate,
    required this.onDelete,
    required this.canDelete,
    this.onDeleteUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [theme.primaryColor, theme.secondaryColor],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
            border: isSelected
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<_SlideCardAction>(
          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.white70),
          tooltip: 'Slide actions',
          color: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _SlideCardAction.duplicate,
              child: _SlideActionLabel(
                icon: Icons.content_copy,
                label: 'Duplicate',
              ),
            ),
            PopupMenuItem(
              value: _SlideCardAction.delete,
              child: _SlideActionLabel(
                icon: canDelete ? Icons.delete_outline : Icons.lock_outline,
                label: canDelete ? 'Delete' : 'Keep last slide',
                subtitle: canDelete ? null : 'Presentation needs one slide',
                isDestructive: canDelete,
              ),
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case _SlideCardAction.duplicate:
                onDuplicate();
              case _SlideCardAction.delete:
                if (canDelete) {
                  onDelete();
                } else {
                  onDeleteUnavailable?.call();
                }
            }
          },
        ),
      ],
    );
  }
}

class _ComponentCountBadge extends StatelessWidget {
  final int count;
  final Color accentColor;

  const _ComponentCountBadge({required this.count, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$count ${count == 1 ? 'item' : 'items'}',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SlideActionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;

  const _SlideActionLabel({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.redAccent
        : subtitle == null
        ? Colors.white70
        : Colors.amberAccent;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: color)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _SlideCardAction { duplicate, delete }

@Preview(name: 'Slide thumbnail card', size: Size(280, 190))
Widget slideThumbnailCardPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 250,
          child: SlideThumbnailCard(
            slide: _previewSlide(),
            index: 0,
            isSelected: true,
            theme: _previewTheme(),
            slideSize: const Size(1920, 1080),
            onSelect: () {},
            onDuplicate: () {},
            onDelete: () {},
            canMoveDown: true,
          ),
        ),
      ),
    ),
  );
}

Slide _previewSlide() {
  return Slide(
    id: 'preview-slide',
    title: 'Quarterly Review',
    backgroundColor: const Color(0xFF0F172A),
    components: [
      PresentationComponent(
        id: 'preview-title',
        type: ComponentType.richText,
        position: const Offset(160, 120),
        size: const Size(960, 160),
        richText: RichTextContent(
          text: 'Quarterly Review',
          style: const TextStyle(color: Colors.white, fontSize: 58),
        ),
      ),
      PresentationComponent(
        id: 'preview-metric',
        type: ComponentType.shape,
        position: const Offset(1180, 250),
        size: const Size(420, 360),
        backgroundColor: const Color(0xFF38BDF8),
      ),
    ],
  );
}

PresentationTheme _previewTheme() {
  return PresentationTheme(
    id: 'thumbnail-preview',
    name: 'Thumbnail Preview',
    primaryColor: const Color(0xFF38BDF8),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
    bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
    colorPalette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
  );
}
