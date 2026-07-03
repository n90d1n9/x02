import 'presentation_component.dart';

class ComponentLayerItem {
  final PresentationComponent component;
  final String title;
  final String typeLabel;
  final int originalIndex;

  const ComponentLayerItem({
    required this.component,
    required this.title,
    required this.typeLabel,
    required this.originalIndex,
  });
}
