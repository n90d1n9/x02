import '../models/component.dart';
import '../models/component_layer_filter.dart';
import '../models/component_layer_item.dart';
import '../models/presentation_component.dart';
import '../models/slide.dart';

class ComponentLayerService {
  static const int _maxTitleLength = 34;

  const ComponentLayerService();

  List<ComponentLayerItem> layersFor(Slide slide) {
    final entries = slide.components.indexed.toList()
      ..sort((a, b) {
        final zOrder = b.$2.zIndex.compareTo(a.$2.zIndex);
        if (zOrder != 0) return zOrder;

        return b.$1.compareTo(a.$1);
      });

    return entries.map((entry) {
      final component = entry.$2;
      return ComponentLayerItem(
        component: component,
        title: titleFor(component),
        typeLabel: typeLabelFor(component.type),
        originalIndex: entry.$1,
      );
    }).toList();
  }

  List<ComponentLayerItem> filterLayers(
    List<ComponentLayerItem> layers,
    String query, {
    ComponentLayerFilter filter = ComponentLayerFilter.all,
  }) {
    return _filterByState(_filterByQuery(layers, query), filter);
  }

  Map<ComponentLayerFilter, int> filterCounts(
    List<ComponentLayerItem> layers,
    String query,
  ) {
    final searchedLayers = _filterByQuery(layers, query);

    return {
      for (final filter in ComponentLayerFilter.values)
        filter: _filterByState(searchedLayers, filter).length,
    };
  }

  String? previousLayerId(List<ComponentLayerItem> layers, String? selectedId) {
    final selectedIndex = _selectedIndex(layers, selectedId);
    if (selectedIndex <= 0) return null;

    return layers[selectedIndex - 1].component.id;
  }

  String? nextLayerId(List<ComponentLayerItem> layers, String? selectedId) {
    final selectedIndex = _selectedIndex(layers, selectedId);
    if (selectedIndex == -1 || selectedIndex >= layers.length - 1) {
      return null;
    }

    return layers[selectedIndex + 1].component.id;
  }

  List<ComponentLayerItem> _filterByQuery(
    List<ComponentLayerItem> layers,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return layers;

    return layers.where((item) {
      return _searchLabels(
            item,
          ).any((label) => label.contains(normalizedQuery)) ||
          _stateLabels(item).any((label) => label.contains(normalizedQuery));
    }).toList();
  }

  int _selectedIndex(List<ComponentLayerItem> layers, String? selectedId) {
    if (selectedId == null) return -1;

    return layers.indexWhere((item) => item.component.id == selectedId);
  }

  List<ComponentLayerItem> _filterByState(
    List<ComponentLayerItem> layers,
    ComponentLayerFilter filter,
  ) {
    if (filter == ComponentLayerFilter.all) return layers;

    return layers.where((item) {
      return switch (filter) {
        ComponentLayerFilter.all => true,
        ComponentLayerFilter.visible => item.component.isVisible,
        ComponentLayerFilter.hidden => !item.component.isVisible,
        ComponentLayerFilter.locked => item.component.isLocked,
      };
    }).toList();
  }

  String titleFor(PresentationComponent component) {
    final customName = component.layerName?.trim();
    if (customName != null && customName.isNotEmpty) {
      return _truncate(customName);
    }

    final text = component.richText?.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .firstOrNull;
    final title = text ?? typeLabelFor(component.type);

    return _truncate(title);
  }

  String typeLabelFor(ComponentType type) {
    switch (type) {
      case ComponentType.richText:
        return 'Text';
      case ComponentType.image:
        return 'Image';
      case ComponentType.shape:
        return 'Rectangle';
      case ComponentType.circle:
        return 'Circle';
      case ComponentType.triangle:
        return 'Triangle';
      case ComponentType.chart:
        return 'Chart';
      case ComponentType.video:
        return 'Video';
      case ComponentType.audio:
        return 'Audio';
      case ComponentType.diagram:
        return 'Diagram';
      case ComponentType.icon:
        return 'Icon';
      case ComponentType.gif:
        return 'GIF';
      case ComponentType.hotspot:
        return 'Hotspot';
      case ComponentType.poll:
        return 'Poll';
      case ComponentType.quiz:
        return 'Quiz';
      case ComponentType.countdown:
        return 'Countdown';
      case ComponentType.progressBar:
        return 'Progress';
      case ComponentType.lottie:
        return 'Lottie';
      case ComponentType.particles:
        return 'Particles';
      case ComponentType.gradient:
        return 'Gradient';
      case ComponentType.unknown:
        return 'Unknown';
    }
  }

  List<String> _stateLabels(ComponentLayerItem item) {
    return [
      item.component.isVisible ? 'visible' : 'hidden',
      item.component.isLocked ? 'locked' : 'editable',
    ];
  }

  List<String> _searchLabels(ComponentLayerItem item) {
    return [
      item.title,
      item.typeLabel,
      item.component.id,
      item.component.layerName ?? '',
      item.component.richText?.text ?? '',
    ].map((label) => label.toLowerCase()).toList();
  }

  String _truncate(String title) {
    return title.length <= _maxTitleLength
        ? title
        : '${title.substring(0, _maxTitleLength - 1)}...';
  }
}
