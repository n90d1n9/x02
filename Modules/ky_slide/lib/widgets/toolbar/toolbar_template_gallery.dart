import 'package:flutter/material.dart';

import '../../models/slide_template.dart';
import '../../services/slide_template_visual_service.dart';
import '../previews/template_preview_thumbnail.dart';
import 'toolbar_gallery_tile.dart';

/// Ribbon gallery for creating slides from branded template recipes.
class ToolbarTemplateGallery extends StatelessWidget {
  final List<SlideTemplateRecipe> templates;
  final List<Color> palette;
  final Color secondaryColor;
  final ValueChanged<SlideTemplateType> onCreateTemplate;
  final bool compact;

  const ToolbarTemplateGallery({
    super.key,
    required this.templates,
    required this.palette,
    required this.secondaryColor,
    required this.onCreateTemplate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final template in templates) _buildTemplateTile(template),
      ],
    );
  }

  Widget _buildTemplateTile(SlideTemplateRecipe template) {
    final accentColor = SlideTemplateVisualService.accentFor(
      template.type,
      palette,
    );

    return ToolbarGalleryTile(
      label: template.name,
      tooltip: 'Create ${template.name} slide',
      compact: compact,
      borderColor: accentColor.withValues(alpha: 0.32),
      compactWidth: 82,
      width: 92,
      compactPreviewWidth: 57,
      previewWidth: 57,
      preview: TemplatePreviewThumbnail(
        type: template.type,
        accentColor: accentColor,
        secondaryColor: secondaryColor,
      ),
      onPressed: () => onCreateTemplate(template.type),
    );
  }
}
