import 'package:flutter/material.dart';

import '../../models/slide_template.dart';
import '../../services/slide_template_visual_service.dart';
import 'sidebar_action_card.dart';
import 'sidebar_metadata_pill.dart';
import 'template_preview_thumbnail.dart';

class TemplateActionCard extends StatelessWidget {
  final SlideTemplateRecipe recipe;
  final Color accentColor;
  final Color secondaryColor;
  final VoidCallback onPressed;

  const TemplateActionCard({
    super.key,
    required this.recipe,
    required this.accentColor,
    required this.secondaryColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SidebarActionCard(
      margin: const EdgeInsets.only(bottom: 6),
      accentColor: accentColor,
      onPressed: onPressed,
      semanticsLabel: '${recipe.name}. ${recipe.actionLabel}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: TemplatePreviewThumbnail(
              type: recipe.type,
              accentColor: accentColor,
              secondaryColor: secondaryColor,
            ),
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
                        recipe.name,
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
                    _TemplateActionBadge(
                      label: recipe.actionLabel,
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recipe.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    SidebarMetadataPill(
                      icon: SlideTemplateVisualService.iconForCategory(
                        recipe.category,
                      ),
                      label: 'Category: ${recipe.category.label}',
                      color: accentColor,
                    ),
                    SidebarMetadataPill(
                      icon: Icons.layers_outlined,
                      label:
                          '${recipe.componentCount} ${recipe.componentCount == 1 ? 'item' : 'items'}',
                      color: Colors.white54,
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
}

class _TemplateActionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TemplateActionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 82),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: color, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
