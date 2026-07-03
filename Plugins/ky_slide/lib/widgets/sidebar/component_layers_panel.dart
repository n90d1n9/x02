import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/component_layer_filter.dart';
import '../../models/component_layer_item.dart';
import '../../services/component_layer_service.dart';
import '../../states/component_layer_actions_provider.dart';
import '../../states/component_provider.dart';
import '../../states/history_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import 'component_layer_commands.dart';
import 'component_layer_action_card.dart';
import 'component_layer_reorder_list.dart';
import 'layer_rename_dialog.dart';
import 'sidebar_command_button.dart';
import 'sidebar_empty_state.dart';
import 'sidebar_filter_chips.dart';
import 'sidebar_result_summary.dart';
import 'sidebar_search_field.dart';
import 'sidebar_section.dart';

class ComponentLayersPanel extends ConsumerWidget {
  final ComponentLayerService layerService;

  const ComponentLayersPanel({
    super.key,
    this.layerService = const ComponentLayerService(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final allLayers = layerService.layersFor(currentSlide);
    final query = ref.watch(layerSearchQueryProvider);
    final activeFilter = ref.watch(layerFilterProvider);
    final layerCounts = layerService.filterCounts(allLayers, query);
    final layers = layerService.filterLayers(
      allLayers,
      query,
      filter: activeFilter,
    );
    final hasActiveFilters =
        query.trim().isNotEmpty || activeFilter != ComponentLayerFilter.all;
    final selectedId = ref.watch(selectedComponentProvider);
    final hasSelectedLayer = allLayers.any(
      (item) => item.component.id == selectedId,
    );
    final selectedLayer = _selectedLayer(allLayers, selectedId);
    final isSelectedLayerFilteredOut =
        selectedLayer != null &&
        hasActiveFilters &&
        !layers.any((item) => item.component.id == selectedId);
    final previousLayerId = layerService.previousLayerId(layers, selectedId);
    final nextLayerId = layerService.nextLayerId(layers, selectedId);
    final hasHiddenLayers = allLayers.any((item) => !item.component.isVisible);
    final hasLockedLayers = allLayers.any((item) => item.component.isLocked);
    final layerActions = ref.read(componentLayerActionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: SidebarSection(
        title: 'Layers',
        subtitle: 'Top-to-bottom object stack',
        icon: Icons.layers_outlined,
        gradientColors: [
          presentation.theme.primaryColor,
          presentation.theme.secondaryColor,
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SidebarSearchField(
              value: query,
              hintText: 'Search layers',
              accentColor: presentation.theme.primaryColor,
              onChanged: (value) {
                ref.read(layerSearchQueryProvider.notifier).state = value;
              },
              onClear: () {
                ref.read(layerSearchQueryProvider.notifier).state = '';
              },
            ),
            const SizedBox(height: 10),
            SidebarResultSummary(
              count: layers.length,
              isFiltered: hasActiveFilters,
              singularLabel: 'object',
              pluralLabel: 'objects',
            ),
            const SizedBox(height: 10),
            SidebarFilterChips<ComponentLayerFilter>(
              options: _layerFilterOptions(layerCounts),
              selectedValue: activeFilter,
              accentColor: presentation.theme.primaryColor,
              onSelected: (filter) {
                ref.read(layerFilterProvider.notifier).state = filter;
              },
            ),
            const SizedBox(height: 10),
            ComponentLayerCommands(
              accentColor: presentation.theme.primaryColor,
              hasHiddenLayers: hasHiddenLayers,
              hasLockedLayers: hasLockedLayers,
              canRename: selectedLayer != null,
              hasSelectedLayer: hasSelectedLayer,
              canSelectAbove: previousLayerId != null,
              canSelectBelow: nextLayerId != null,
              onShowAll: layerActions.showAllLayers,
              onUnlockAll: layerActions.unlockAllLayers,
              onRename: () {
                _openRenameDialog(
                  context,
                  ref,
                  selectedLayer!,
                  presentation.theme.primaryColor,
                );
              },
              onDuplicate: layerActions.duplicateSelectedLayer,
              onDelete: layerActions.deleteSelectedLayer,
              onSelectAbove: () {
                ref.read(selectedComponentProvider.notifier).state =
                    previousLayerId;
              },
              onSelectBelow: () {
                ref.read(selectedComponentProvider.notifier).state =
                    nextLayerId;
              },
              onBringToFront: layerActions.bringSelectedLayerToFront,
              onMoveForward: layerActions.moveSelectedLayerForward,
              onMoveBackward: layerActions.moveSelectedLayerBackward,
              onSendToBack: layerActions.sendSelectedLayerToBack,
            ),
            const SizedBox(height: 12),
            if (allLayers.isEmpty)
              const SidebarEmptyState(message: 'No objects on this slide')
            else ...[
              if (isSelectedLayerFilteredOut) ...[
                _FilteredSelectionNotice(
                  layerTitle: selectedLayer.title,
                  accentColor: presentation.theme.primaryColor,
                  onReveal: () {
                    ref.read(layerSearchQueryProvider.notifier).state = '';
                    ref.read(layerFilterProvider.notifier).state =
                        ComponentLayerFilter.all;
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (layers.isEmpty)
                SidebarEmptyState(
                  message: 'No matching layers',
                  actionLabel: 'Clear filters',
                  actionIcon: Icons.filter_alt_off_outlined,
                  onAction: () {
                    ref.read(layerSearchQueryProvider.notifier).state = '';
                    ref.read(layerFilterProvider.notifier).state =
                        ComponentLayerFilter.all;
                  },
                )
              else if (!hasActiveFilters)
                ComponentLayerReorderList(
                  layers: layers,
                  selectedId: selectedId,
                  accentColor: presentation.theme.primaryColor,
                  onReorder: layerActions.reorderLayers,
                  onSelect: (item) {
                    ref.read(selectedComponentProvider.notifier).state =
                        item.component.id;
                  },
                  onToggleVisibility: (item) {
                    layerActions.setLayerVisibility(
                      item.component.id,
                      !item.component.isVisible,
                    );
                  },
                  onToggleLock: (item) {
                    layerActions.setLayerLocked(
                      item.component.id,
                      !item.component.isLocked,
                    );
                  },
                )
              else
                ...layers.map(
                  (item) => ComponentLayerActionCard(
                    item: item,
                    isSelected: item.component.id == selectedId,
                    accentColor: presentation.theme.primaryColor,
                    onPressed: () {
                      ref.read(selectedComponentProvider.notifier).state =
                          item.component.id;
                    },
                    onToggleVisibility: () {
                      layerActions.setLayerVisibility(
                        item.component.id,
                        !item.component.isVisible,
                      );
                    },
                    onToggleLock: () {
                      layerActions.setLayerLocked(
                        item.component.id,
                        !item.component.isLocked,
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ComponentLayerItem layer,
    Color accentColor,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return LayerRenameDialog(
          initialName: layer.component.layerName ?? '',
          fallbackName: layer.title,
          accentColor: accentColor,
          onRename: (name) {
            final hasName = name?.trim().isNotEmpty == true;
            ref.read(historyProvider.notifier).recordPresentationMutation((
              notifier,
            ) {
              notifier.renameComponentLayer(layer.component.id, name);
            }, label: hasName ? 'Rename layer' : 'Clear layer name');
          },
        );
      },
    );
  }
}

class _FilteredSelectionNotice extends StatelessWidget {
  final String layerTitle;
  final Color accentColor;
  final VoidCallback onReveal;

  const _FilteredSelectionNotice({
    required this.layerTitle,
    required this.accentColor,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 17, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selected layer hidden by filters: $layerTitle',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SidebarCommandButton(
            icon: Icons.center_focus_strong_outlined,
            label: 'Reveal',
            isEnabled: true,
            accentColor: accentColor,
            height: 30,
            iconSize: 14,
            fontSize: 10,
            onPressed: onReveal,
          ),
        ],
      ),
    );
  }
}

ComponentLayerItem? _selectedLayer(
  List<ComponentLayerItem> layers,
  String? selectedId,
) {
  for (final layer in layers) {
    if (layer.component.id == selectedId) return layer;
  }

  return null;
}

List<SidebarFilterChipOption<ComponentLayerFilter>> _layerFilterOptions(
  Map<ComponentLayerFilter, int> counts,
) {
  return [
    SidebarFilterChipOption<ComponentLayerFilter>(
      value: ComponentLayerFilter.all,
      label: 'All',
      icon: Icons.layers_outlined,
      badgeLabel: '${counts[ComponentLayerFilter.all] ?? 0}',
    ),
    SidebarFilterChipOption<ComponentLayerFilter>(
      value: ComponentLayerFilter.visible,
      label: 'Visible',
      icon: Icons.visibility_outlined,
      badgeLabel: '${counts[ComponentLayerFilter.visible] ?? 0}',
    ),
    SidebarFilterChipOption<ComponentLayerFilter>(
      value: ComponentLayerFilter.hidden,
      label: 'Hidden',
      icon: Icons.visibility_off,
      badgeLabel: '${counts[ComponentLayerFilter.hidden] ?? 0}',
    ),
    SidebarFilterChipOption<ComponentLayerFilter>(
      value: ComponentLayerFilter.locked,
      label: 'Locked',
      icon: Icons.lock_outline,
      badgeLabel: '${counts[ComponentLayerFilter.locked] ?? 0}',
    ),
  ];
}
