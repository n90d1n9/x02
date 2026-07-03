import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sidebar_menu_item.dart';
import '../models/sidebar_section_id.dart';
import '../models/slide.dart';
import '../models/slide_navigator_density.dart';
import '../models/style/presentation_theme.dart';
import '../services/slide_search_service.dart';
import '../services/slide_layout_service.dart';
import '../services/slide_template_service.dart';
import '../states/presentation_provider.dart';
import '../states/sidebar_panel_provider.dart';
import '../states/slide_actions_provider.dart';
import 'sidebar/component_layers_panel.dart';
import 'sidebar/component_arrange_panel.dart';
import 'sidebar/design_assist_panel.dart';
import 'sidebar/history_panel.dart';
import 'sidebar/presentation_file_panel.dart';
import 'sidebar/sidebar_empty_state.dart';
import 'sidebar/sidebar_menu.dart';
import 'sidebar/sidebar_result_summary.dart';
import 'sidebar/sidebar_search_field.dart';
import 'sidebar/slide_creation_button.dart';
import 'sidebar/slide_navigator_density_control.dart';
import 'sidebar/slide_outline_panel.dart';
import 'sidebar/slide_thumbnail_card.dart';

/// Sidebar shell for slide creation, navigation, file, and support panels.
class SlidePanel extends ConsumerWidget {
  const SlidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final selectedMenu = ref.watch(activeSidebarMenuProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SlideCreationButton(
            accentColor: presentation.theme.primaryColor,
            secondaryColor: presentation.theme.secondaryColor,
            templatePalette: presentation.theme.colorPalette,
            layouts: SlideLayoutService.recipes,
            templates: SlideTemplateService.recipes,
            onCreateBlank: () => ref.read(slideActionsProvider).addSlide(),
            onOpenTemplates: () => _openDesignAssist(ref),
            onCreateLayout: (type) {
              ref.read(slideActionsProvider).addLayoutSlide(type);
            },
            onCreateTemplate: (type) {
              ref.read(slideActionsProvider).addTemplateSlide(type);
            },
          ),
        ),
        SidebarMenu(
          selectedItem: selectedMenu,
          accentColor: presentation.theme.primaryColor,
          onSelected: (item) {
            ref.read(activeSidebarMenuProvider.notifier).state = item;
          },
        ),
        const Divider(height: 1, color: Color(0xFF334155)),
        Expanded(child: _buildMenuContent(context, ref, selectedMenu)),
      ],
    );
  }

  Widget _buildMenuContent(
    BuildContext context,
    WidgetRef ref,
    SidebarMenuItem selectedMenu,
  ) {
    switch (selectedMenu) {
      case SidebarMenuItem.slides:
        return _SlideList(
          onLastSlideDelete: () => _showLastSlideDeleteMessage(context),
        );
      case SidebarMenuItem.design:
        return const SingleChildScrollView(child: DesignAssistPanel());
      case SidebarMenuItem.outline:
        return const SingleChildScrollView(child: SlideOutlinePanel());
      case SidebarMenuItem.layers:
        return const SingleChildScrollView(child: ComponentLayersPanel());
      case SidebarMenuItem.arrange:
        return const SingleChildScrollView(child: ComponentArrangePanel());
      case SidebarMenuItem.history:
        return const SingleChildScrollView(child: HistoryPanel());
      case SidebarMenuItem.files:
        return const SingleChildScrollView(child: PresentationFilePanel());
    }
  }

  void _showLastSlideDeleteMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A presentation needs at least one slide.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDesignAssist(WidgetRef ref) {
    final designAssistExpanded = sidebarSectionExpandedProvider(
      SidebarSectionId.designAssist,
    );

    ref.read(activeSidebarMenuProvider.notifier).state = SidebarMenuItem.design;
    ref.read(designAssistExpanded.notifier).state = true;
  }
}

class _SlideList extends ConsumerWidget {
  final VoidCallback onLastSlideDelete;

  const _SlideList({required this.onLastSlideDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final canDeleteSlides = presentation.slides.length > 1;
    final query = ref.watch(slideSearchQueryProvider);
    final matchingIndexes = SlideSearchService.matchingIndexes(
      presentation,
      query,
    );
    final isFiltering = query.trim().isNotEmpty;
    final density = ref.watch(slideNavigatorDensityProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
          child: SidebarSearchField(
            value: query,
            hintText: 'Search slides',
            accentColor: presentation.theme.primaryColor,
            onChanged: (value) {
              ref.read(slideSearchQueryProvider.notifier).state = value;
            },
            onClear: () {
              ref.read(slideSearchQueryProvider.notifier).state = '';
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: SidebarResultSummary(
                  count: matchingIndexes.length,
                  isFiltered: isFiltering,
                  singularLabel: 'slide',
                  pluralLabel: 'slides',
                ),
              ),
              const SizedBox(width: 8),
              SlideNavigatorDensityControl(
                density: density,
                accentColor: presentation.theme.primaryColor,
                onSelected: (value) {
                  ref.read(slideNavigatorDensityProvider.notifier).state =
                      value;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: matchingIndexes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: SidebarEmptyState(
                    message: isFiltering
                        ? 'No matching slides'
                        : 'No slides yet',
                    actionLabel: isFiltering ? 'Clear search' : null,
                    onAction: isFiltering
                        ? () {
                            ref.read(slideSearchQueryProvider.notifier).state =
                                '';
                          }
                        : null,
                  ),
                )
              : isFiltering
              ? ListView.builder(
                  itemCount: matchingIndexes.length,
                  itemBuilder: (context, resultIndex) {
                    final index = matchingIndexes[resultIndex];

                    return _buildSlideCard(
                      ref: ref,
                      slide: presentation.slides[index],
                      index: index,
                      selectedIndex: presentation.currentSlideIndex,
                      theme: presentation.theme,
                      slideSize: presentation.slideSize,
                      slideCount: presentation.slides.length,
                      canDeleteSlides: canDeleteSlides,
                      density: density,
                    );
                  },
                )
              : ReorderableListView.builder(
                  itemCount: presentation.slides.length,
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(slideActionsProvider)
                        .moveSlide(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    return _buildSlideCard(
                      ref: ref,
                      slide: presentation.slides[index],
                      index: index,
                      selectedIndex: presentation.currentSlideIndex,
                      theme: presentation.theme,
                      slideSize: presentation.slideSize,
                      slideCount: presentation.slides.length,
                      canDeleteSlides: canDeleteSlides,
                      density: density,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSlideCard({
    required WidgetRef ref,
    required Slide slide,
    required int index,
    required int selectedIndex,
    required PresentationTheme theme,
    required Size slideSize,
    required int slideCount,
    required bool canDeleteSlides,
    required SlideNavigatorDensity density,
  }) {
    return SlideThumbnailCard(
      key: ValueKey(slide.id),
      slide: slide,
      index: index,
      isSelected: index == selectedIndex,
      theme: theme,
      slideSize: slideSize,
      density: density,
      canDelete: canDeleteSlides,
      canMoveUp: index > 0,
      canMoveDown: index < slideCount - 1,
      onSelect: () =>
          ref.read(presentationProvider.notifier).setCurrentSlide(index),
      onMoveUp: () {
        ref.read(slideActionsProvider).moveSlide(index, index - 1);
      },
      onMoveDown: () {
        ref.read(slideActionsProvider).moveSlide(index, index + 1);
      },
      onDuplicate: () {
        ref.read(slideActionsProvider).duplicateSlide(index: index);
      },
      onDelete: () {
        final deleted = ref
            .read(slideActionsProvider)
            .deleteSlide(index: index);
        if (!deleted) onLastSlideDelete();
      },
      onDeleteUnavailable: onLastSlideDelete,
    );
  }
}
