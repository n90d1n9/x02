import 'package:flutter/material.dart';

import '../../models/component_layer_item.dart';
import 'component_layer_action_card.dart';

class ComponentLayerReorderList extends StatelessWidget {
  final List<ComponentLayerItem> layers;
  final String? selectedId;
  final Color accentColor;
  final VoidCallback? onReorderUnavailable;
  final void Function(List<String> topToBottomIds) onReorder;
  final void Function(ComponentLayerItem item) onSelect;
  final void Function(ComponentLayerItem item) onToggleVisibility;
  final void Function(ComponentLayerItem item) onToggleLock;

  const ComponentLayerReorderList({
    super.key,
    required this.layers,
    required this.selectedId,
    required this.accentColor,
    required this.onReorder,
    required this.onSelect,
    required this.onToggleVisibility,
    required this.onToggleLock,
    this.onReorderUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    if (layers.length < 2) {
      return Column(children: _layerRows());
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: layers.length,
      onReorderItem: _handleReorder,
      itemBuilder: (context, index) {
        final item = layers[index];

        return _ReorderableLayerRow(
          key: ValueKey('layer-row-${item.component.id}'),
          index: index,
          item: item,
          isSelected: item.component.id == selectedId,
          accentColor: accentColor,
          onSelect: () => onSelect(item),
          onToggleVisibility: () => onToggleVisibility(item),
          onToggleLock: () => onToggleLock(item),
        );
      },
    );
  }

  List<Widget> _layerRows() {
    return layers.map((item) {
      return ComponentLayerActionCard(
        key: ValueKey('layer-row-${item.component.id}'),
        item: item,
        isSelected: item.component.id == selectedId,
        accentColor: accentColor,
        onPressed: () => onSelect(item),
        onToggleVisibility: () => onToggleVisibility(item),
        onToggleLock: () => onToggleLock(item),
      );
    }).toList();
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= layers.length) {
      onReorderUnavailable?.call();
      return;
    }

    if (newIndex < 0 || newIndex >= layers.length) {
      onReorderUnavailable?.call();
      return;
    }
    if (oldIndex == newIndex) return;

    final orderedIds = layers.map((item) => item.component.id).toList();
    final movedId = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, movedId);
    onReorder(orderedIds);
  }
}

class _ReorderableLayerRow extends StatelessWidget {
  final int index;
  final ComponentLayerItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onSelect;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;

  const _ReorderableLayerRow({
    super.key,
    required this.index,
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onSelect,
    required this.onToggleVisibility,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Tooltip(
            message: 'Drag to reorder layer',
            child: Container(
              width: 28,
              height: 52,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.drag_handle,
                size: 18,
                color: Colors.white54,
              ),
            ),
          ),
        ),
        Expanded(
          child: ComponentLayerActionCard(
            item: item,
            isSelected: isSelected,
            accentColor: accentColor,
            onPressed: onSelect,
            onToggleVisibility: onToggleVisibility,
            onToggleLock: onToggleLock,
          ),
        ),
      ],
    );
  }
}
