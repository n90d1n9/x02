import 'package:flutter/material.dart';

import '../../models/slide_layout.dart';
import '../../models/slide_template.dart';
import 'slide_creation_menu_rows.dart';

class SlideCreationButton extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final List<Color> templatePalette;
  final List<SlideLayoutRecipe> layouts;
  final List<SlideTemplateRecipe> templates;
  final VoidCallback onCreateBlank;
  final VoidCallback onOpenTemplates;
  final ValueChanged<SlideLayoutType> onCreateLayout;
  final ValueChanged<SlideTemplateType> onCreateTemplate;

  const SlideCreationButton({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.layouts,
    required this.templates,
    required this.onCreateBlank,
    required this.onOpenTemplates,
    required this.onCreateLayout,
    required this.onCreateTemplate,
    this.templatePalette = const [],
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accentColor, secondaryColor]),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onCreateBlank,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 19),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'New Slide',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: Colors.white.withValues(alpha: 0.22)),
              PopupMenuButton<_SlideCreationMenuAction>(
                tooltip: 'New slide options',
                color: const Color(0xFF111827),
                elevation: 12,
                constraints: const BoxConstraints(minWidth: 240),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
                onSelected: (action) {
                  if (action.openTemplates) {
                    onOpenTemplates();
                    return;
                  }

                  final layoutType = action.layoutType;
                  if (layoutType != null) {
                    onCreateLayout(layoutType);
                    return;
                  }

                  final templateType = action.templateType;
                  if (templateType != null) {
                    onCreateTemplate(templateType);
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: _SlideCreationMenuAction.openTemplates(),
                      child: SlideCreationCommandRow(
                        icon: Icons.auto_awesome,
                        label: 'Browse templates',
                        subtitle: 'Open Design Assist',
                      ),
                    ),
                    const PopupMenuDivider(height: 8),
                    const PopupMenuItem(
                      enabled: false,
                      child: SlideCreationMenuSectionLabel(label: 'Layouts'),
                    ),
                    ...layouts.map((layout) {
                      return PopupMenuItem(
                        value: _SlideCreationMenuAction.layout(layout.type),
                        child: SlideCreationLayoutRow(
                          layout: layout,
                          accentColor: secondaryColor,
                        ),
                      );
                    }),
                    const PopupMenuDivider(height: 8),
                    const PopupMenuItem(
                      enabled: false,
                      child: SlideCreationMenuSectionLabel(label: 'Templates'),
                    ),
                    ...templates.map((template) {
                      return PopupMenuItem(
                        value: _SlideCreationMenuAction.template(template.type),
                        child: SlideCreationTemplateRow(
                          template: template,
                          secondaryColor: secondaryColor,
                          templatePalette: templatePalette,
                        ),
                      );
                    }),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideCreationMenuAction {
  final bool openTemplates;
  final SlideLayoutType? layoutType;
  final SlideTemplateType? templateType;

  const _SlideCreationMenuAction.openTemplates()
    : openTemplates = true,
      layoutType = null,
      templateType = null;

  const _SlideCreationMenuAction.layout(this.layoutType)
    : openTemplates = false,
      templateType = null;

  const _SlideCreationMenuAction.template(this.templateType)
    : openTemplates = false,
      layoutType = null;
}
