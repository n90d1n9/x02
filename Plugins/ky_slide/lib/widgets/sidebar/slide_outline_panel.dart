import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sidebar_section_id.dart';
import '../../services/presentation_outline_service.dart';
import '../../states/component_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import 'sidebar_empty_state.dart';
import 'sidebar_result_summary.dart';
import 'sidebar_search_field.dart';
import 'sidebar_section.dart';
import 'slide_outline_action_card.dart';

class SlideOutlinePanel extends ConsumerWidget {
  const SlideOutlinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final outline = PresentationOutlineService.build(presentation);
    final query = ref.watch(outlineSearchQueryProvider);
    final hasQuery = query.trim().isNotEmpty;
    final filteredOutline = PresentationOutlineService.filter(outline, query);
    final theme = presentation.theme;
    final sectionId = SidebarSectionId.outline;
    final isExpanded = ref.watch(sidebarSectionExpandedProvider(sectionId));

    return SidebarSection(
      title: 'Outline',
      subtitle: 'Jump through the presentation structure.',
      icon: Icons.view_list,
      gradientColors: [theme.secondaryColor, theme.primaryColor],
      collapsible: true,
      initiallyExpanded: true,
      isExpanded: isExpanded,
      onExpandedChanged: (value) {
        ref.read(sidebarSectionExpandedProvider(sectionId).notifier).state =
            value;
      },
      child: Column(
        children: [
          SidebarSearchField(
            value: query,
            hintText: 'Search outline',
            accentColor: theme.primaryColor,
            onChanged: (value) {
              ref.read(outlineSearchQueryProvider.notifier).state = value;
            },
            onClear: () {
              ref.read(outlineSearchQueryProvider.notifier).state = '';
            },
          ),
          const SizedBox(height: 10),
          SidebarResultSummary(
            count: filteredOutline.length,
            isFiltered: hasQuery,
            singularLabel: 'slide',
            pluralLabel: 'slides',
          ),
          const SizedBox(height: 8),
          if (filteredOutline.isEmpty)
            SidebarEmptyState(
              message: hasQuery ? 'No matching slides' : 'No slides yet',
              actionLabel: hasQuery ? 'Clear search' : null,
              onAction: hasQuery
                  ? () {
                      ref.read(outlineSearchQueryProvider.notifier).state = '';
                    }
                  : null,
            )
          else
            ...filteredOutline.map(
              (item) => SlideOutlineActionCard(
                item: item,
                isSelected: item.index == presentation.currentSlideIndex,
                accentColor: theme.primaryColor,
                onPressed: () {
                  ref
                      .read(presentationProvider.notifier)
                      .setCurrentSlide(item.index);
                  ref.read(selectedComponentProvider.notifier).state = null;
                },
              ),
            ),
        ],
      ),
    );
  }
}
