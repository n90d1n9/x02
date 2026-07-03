import '../models/presentation_component.dart';
import '../models/selection_identity.dart';
import 'component_layer_service.dart';

/// Builds compact, user-facing identity labels for selected slide objects.
class SelectionIdentityService {
  final ComponentLayerService layerService;

  const SelectionIdentityService({
    this.layerService = const ComponentLayerService(),
  });

  SelectionIdentity identityFor(PresentationComponent component) {
    return SelectionIdentity(
      title: layerService.titleFor(component),
      typeLabel: layerService.typeLabelFor(component.type),
      type: component.type,
      isLocked: component.isLocked,
      isVisible: component.isVisible,
    );
  }
}
