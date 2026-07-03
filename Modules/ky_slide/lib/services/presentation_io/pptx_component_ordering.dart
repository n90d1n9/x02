import '../../models/presentation_component.dart';
import '../../models/slide.dart';

class PptxComponentOrdering {
  const PptxComponentOrdering();

  List<PresentationComponent> orderedComponents(Slide slide) {
    final entries =
        slide.components.indexed.where((entry) => entry.$2.isVisible).toList()
          ..sort((a, b) {
            final layerOrder = a.$2.zIndex.compareTo(b.$2.zIndex);
            if (layerOrder != 0) return layerOrder;

            return a.$1.compareTo(b.$1);
          });

    return entries.map((entry) => entry.$2).toList();
  }
}
