import 'package:flutter/material.dart';

import '../../models/presentation_outline.dart';
import 'sidebar_action_card.dart';
import 'sidebar_metadata_pill.dart';

class SlideOutlineActionCard extends StatelessWidget {
  final SlideOutlineItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onPressed;

  const SlideOutlineActionCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected ? accentColor : Colors.white54;

    return SidebarActionCard(
      accentColor: accentColor,
      selected: isSelected,
      onPressed: onPressed,
      semanticsLabel: 'Go to slide ${item.index + 1}: ${item.title}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideNumberBadge(
            number: item.index + 1,
            isSelected: isSelected,
            color: activeColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SidebarMetadataPill(
                      icon: Icons.layers_outlined,
                      label:
                          '${item.componentCount} ${item.componentCount == 1 ? 'item' : 'items'}',
                      color: activeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.25,
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

class _SlideNumberBadge extends StatelessWidget {
  final int number;
  final bool isSelected;
  final Color color;

  const _SlideNumberBadge({
    required this.number,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
