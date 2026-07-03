import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sidebar_section_id.dart';
import '../../models/slide_template.dart';
import '../../services/slide_template_service.dart';
import '../../services/slide_template_visual_service.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import '../../states/slide_actions_provider.dart';
import 'sidebar_empty_state.dart';
import 'sidebar_filter_chips.dart';
import 'sidebar_result_summary.dart';
import 'sidebar_search_field.dart';
import 'sidebar_section.dart';
import 'template_action_card.dart';
import 'template_customizer_dialog.dart';

class DesignAssistPanel extends ConsumerWidget {
  const DesignAssistPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final theme = presentation.theme;
    final sectionId = SidebarSectionId.designAssist;
    final isExpanded = ref.watch(sidebarSectionExpandedProvider(sectionId));
    final query = ref.watch(designAssistSearchQueryProvider);
    final category = ref.watch(designAssistCategoryProvider);
    final hasActiveFilters = query.trim().isNotEmpty || category != null;
    final categoryCounts = SlideTemplateService.categoryCounts(query);
    final recipes = SlideTemplateService.filterRecipes(
      query,
      category: category,
    );

    return SidebarSection(
      title: 'Design Assist',
      subtitle: 'Feature slides ready for polish and editing.',
      icon: Icons.auto_awesome,
      gradientColors: [theme.primaryColor, theme.secondaryColor],
      collapsible: true,
      initiallyExpanded: false,
      isExpanded: isExpanded,
      onExpandedChanged: (value) {
        ref.read(sidebarSectionExpandedProvider(sectionId).notifier).state =
            value;
      },
      child: Column(
        children: [
          SidebarSearchField(
            value: query,
            hintText: 'Search templates',
            accentColor: theme.primaryColor,
            onChanged: (value) {
              ref.read(designAssistSearchQueryProvider.notifier).state = value;
            },
            onClear: () {
              ref.read(designAssistSearchQueryProvider.notifier).state = '';
            },
          ),
          const SizedBox(height: 10),
          SidebarFilterChips<SlideTemplateCategory?>(
            options: _templateCategoryOptions(categoryCounts),
            selectedValue: category,
            accentColor: theme.primaryColor,
            onSelected: (value) {
              ref.read(designAssistCategoryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 10),
          SidebarResultSummary(
            count: recipes.length,
            isFiltered: hasActiveFilters,
            singularLabel: 'template',
            pluralLabel: 'templates',
          ),
          const SizedBox(height: 8),
          if (recipes.isEmpty)
            SidebarEmptyState(
              message: hasActiveFilters
                  ? 'No matching templates'
                  : 'No templates yet',
              actionLabel: hasActiveFilters ? 'Clear filters' : null,
              actionIcon: Icons.filter_alt_off_outlined,
              onAction: hasActiveFilters
                  ? () {
                      ref.read(designAssistSearchQueryProvider.notifier).state =
                          '';
                      ref.read(designAssistCategoryProvider.notifier).state =
                          null;
                    }
                  : null,
            )
          else
            ...recipes.map((recipe) {
              final accentColor = SlideTemplateVisualService.accentFor(
                recipe.type,
                theme.colorPalette,
              );

              return TemplateActionCard(
                recipe: recipe,
                accentColor: accentColor,
                secondaryColor: theme.secondaryColor,
                onPressed: () =>
                    _openCustomizer(context, ref, recipe, accentColor),
              );
            }),
        ],
      ),
    );
  }

  void _openCustomizer(
    BuildContext context,
    WidgetRef ref,
    SlideTemplateRecipe recipe,
    Color accentColor,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => TemplateCustomizerDialog(
        recipe: recipe,
        accentColor: accentColor,
        onCreate: (customization) {
          _addTemplate(ref, recipe.type, customization);
        },
      ),
    );
  }

  void _addTemplate(
    WidgetRef ref,
    SlideTemplateType type,
    SlideTemplateCustomization customization,
  ) {
    ref
        .read(slideActionsProvider)
        .addTemplateSlide(type, customization: customization);
  }
}

List<SidebarFilterChipOption<SlideTemplateCategory?>> _templateCategoryOptions(
  Map<SlideTemplateCategory, int> categoryCounts,
) {
  final totalCount = categoryCounts.values.fold<int>(
    0,
    (total, count) => total + count,
  );

  return [
    SidebarFilterChipOption<SlideTemplateCategory?>(
      value: null,
      label: 'All',
      icon: Icons.dashboard_outlined,
      badgeLabel: '$totalCount',
    ),
    SidebarFilterChipOption<SlideTemplateCategory?>(
      value: SlideTemplateCategory.cover,
      label: 'Cover',
      icon: SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.cover,
      ),
      badgeLabel: '${categoryCounts[SlideTemplateCategory.cover] ?? 0}',
    ),
    SidebarFilterChipOption<SlideTemplateCategory?>(
      value: SlideTemplateCategory.structure,
      label: 'Flow',
      icon: SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.structure,
      ),
      badgeLabel: '${categoryCounts[SlideTemplateCategory.structure] ?? 0}',
    ),
    SidebarFilterChipOption<SlideTemplateCategory?>(
      value: SlideTemplateCategory.metrics,
      label: 'Metrics',
      icon: SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.metrics,
      ),
      badgeLabel: '${categoryCounts[SlideTemplateCategory.metrics] ?? 0}',
    ),
    SidebarFilterChipOption<SlideTemplateCategory?>(
      value: SlideTemplateCategory.decision,
      label: 'Decision',
      icon: SlideTemplateVisualService.iconForCategory(
        SlideTemplateCategory.decision,
      ),
      badgeLabel: '${categoryCounts[SlideTemplateCategory.decision] ?? 0}',
    ),
  ];
}
