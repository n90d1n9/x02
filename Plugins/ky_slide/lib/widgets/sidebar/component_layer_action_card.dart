import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../../models/component_layer_item.dart';
import 'sidebar_action_card.dart';
import 'sidebar_metadata_pill.dart';

class ComponentLayerActionCard extends StatelessWidget {
  final ComponentLayerItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onPressed;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;

  const ComponentLayerActionCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
    required this.onToggleVisibility,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = item.component.isVisible;
    final isLocked = item.component.isLocked;

    return SidebarActionCard(
      selected: isSelected,
      accentColor: accentColor,
      semanticsLabel: 'Select ${item.title}',
      onPressed: onPressed,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isVisible
                  ? accentColor.withValues(alpha: isSelected ? 0.2 : 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isVisible
                    ? accentColor.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              _iconFor(item.component.type),
              color: isVisible ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isVisible ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    SidebarMetadataPill(
                      icon: Icons.category_outlined,
                      label: item.typeLabel,
                      color: const Color(0xFF38BDF8),
                    ),
                    SidebarMetadataPill(
                      icon: Icons.layers_outlined,
                      label: 'z ${item.component.zIndex}',
                      color: const Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LayerIconButton(
                tooltip: isVisible ? 'Hide layer' : 'Show layer',
                icon: isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off,
                isActive: isVisible,
                onPressed: onToggleVisibility,
              ),
              _LayerIconButton(
                tooltip: isLocked ? 'Unlock layer' : 'Lock layer',
                icon: isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                isActive: isLocked,
                activeColor: const Color(0xFFF59E0B),
                onPressed: onToggleLock,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ComponentType type) {
    switch (type) {
      case ComponentType.richText:
        return Icons.text_fields;
      case ComponentType.image:
      case ComponentType.gif:
        return Icons.image_outlined;
      case ComponentType.shape:
        return Icons.crop_square;
      case ComponentType.circle:
        return Icons.circle_outlined;
      case ComponentType.triangle:
        return Icons.change_history;
      case ComponentType.chart:
        return Icons.bar_chart;
      case ComponentType.video:
        return Icons.movie_outlined;
      case ComponentType.audio:
        return Icons.graphic_eq;
      case ComponentType.diagram:
        return Icons.account_tree_outlined;
      case ComponentType.icon:
        return Icons.star_outline;
      case ComponentType.hotspot:
        return Icons.touch_app_outlined;
      case ComponentType.poll:
        return Icons.poll_outlined;
      case ComponentType.quiz:
        return Icons.quiz_outlined;
      case ComponentType.countdown:
        return Icons.timer_outlined;
      case ComponentType.progressBar:
        return Icons.stacked_bar_chart;
      case ComponentType.lottie:
        return Icons.animation;
      case ComponentType.particles:
        return Icons.blur_on;
      case ComponentType.gradient:
        return Icons.gradient;
      case ComponentType.unknown:
        return Icons.device_unknown;
    }
  }
}

class _LayerIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _LayerIconButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onPressed,
    this.activeColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: isActive ? activeColor : Colors.white38),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 28),
        onPressed: onPressed,
      ),
    );
  }
}
