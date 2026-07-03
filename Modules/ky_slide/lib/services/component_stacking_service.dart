import '../models/presentation_component.dart';

class ComponentStackingService {
  const ComponentStackingService();

  List<PresentationComponent> moveForward(
    List<PresentationComponent> components,
    String componentId,
  ) {
    return _moveByRank(components, componentId, 1);
  }

  List<PresentationComponent> moveBackward(
    List<PresentationComponent> components,
    String componentId,
  ) {
    return _moveByRank(components, componentId, -1);
  }

  List<PresentationComponent> reorderTopToBottom(
    List<PresentationComponent> components,
    List<String> topToBottomIds,
  ) {
    if (components.length < 2) return components;
    if (topToBottomIds.length != components.length) return components;

    final componentIds = components.map((component) => component.id).toSet();
    final orderedIds = topToBottomIds.toSet();
    if (componentIds.length != orderedIds.length ||
        !componentIds.containsAll(orderedIds)) {
      return components;
    }

    final highestRank = topToBottomIds.length - 1;
    final zIndexById = <String, int>{
      for (final (index, id) in topToBottomIds.indexed) id: highestRank - index,
    };
    var changed = false;
    final reordered = components.map((component) {
      final zIndex = zIndexById[component.id]!;
      if (zIndex == component.zIndex) return component;

      changed = true;
      return component.copyWith(zIndex: zIndex);
    }).toList();

    return changed ? reordered : components;
  }

  List<PresentationComponent> _moveByRank(
    List<PresentationComponent> components,
    String componentId,
    int direction,
  ) {
    if (components.length < 2) return components;

    final entries = components.indexed.toList()
      ..sort((a, b) {
        final zOrder = a.$2.zIndex.compareTo(b.$2.zIndex);
        if (zOrder != 0) return zOrder;

        return a.$1.compareTo(b.$1);
      });
    final currentRank = entries.indexWhere(
      (entry) => entry.$2.id == componentId,
    );
    if (currentRank < 0) return components;

    final nextRank = currentRank + direction;
    if (nextRank < 0 || nextRank >= entries.length) return components;

    final selected = entries.removeAt(currentRank);
    entries.insert(nextRank, selected);

    final zIndexById = <String, int>{
      for (final (rank, entry) in entries.indexed) entry.$2.id: rank,
    };

    return components.map((component) {
      final zIndex = zIndexById[component.id];
      return zIndex == null || zIndex == component.zIndex
          ? component
          : component.copyWith(zIndex: zIndex);
    }).toList();
  }
}
