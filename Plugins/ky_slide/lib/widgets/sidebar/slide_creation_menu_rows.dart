import 'package:flutter/material.dart';

import '../../models/slide_layout.dart';
import '../../models/slide_template.dart';
import '../../services/slide_template_visual_service.dart';
import 'slide_layout_preview_thumbnail.dart';
import 'template_preview_thumbnail.dart';

class SlideCreationMenuSectionLabel extends StatelessWidget {
  final String label;

  const SlideCreationMenuSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class SlideCreationCommandRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const SlideCreationCommandRow({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuRow(
      leading: Icon(icon, size: 18, color: Colors.white70),
      label: label,
      subtitle: subtitle,
    );
  }
}

class SlideCreationLayoutRow extends StatelessWidget {
  final SlideLayoutRecipe layout;
  final Color accentColor;

  const SlideCreationLayoutRow({
    super.key,
    required this.layout,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuRow(
      leading: SizedBox(
        width: 46,
        child: SlideLayoutPreviewThumbnail(
          type: layout.type,
          accentColor: accentColor,
        ),
      ),
      label: layout.name,
      subtitle: layout.actionLabel,
    );
  }
}

class SlideCreationTemplateRow extends StatelessWidget {
  final SlideTemplateRecipe template;
  final Color secondaryColor;
  final List<Color> templatePalette;

  const SlideCreationTemplateRow({
    super.key,
    required this.template,
    required this.secondaryColor,
    required this.templatePalette,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = SlideTemplateVisualService.accentFor(
      template.type,
      templatePalette,
    );

    return _MenuRow(
      leading: SizedBox(
        width: 58,
        child: TemplatePreviewThumbnail(
          type: template.type,
          accentColor: accentColor,
          secondaryColor: secondaryColor,
        ),
      ),
      label: template.name,
      subtitle: template.actionLabel,
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String subtitle;

  const _MenuRow({
    required this.leading,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
