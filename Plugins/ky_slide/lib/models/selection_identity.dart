import 'component.dart';

/// Display metadata for the object currently selected on the slide canvas.
class SelectionIdentity {
  final String title;
  final String typeLabel;
  final ComponentType type;
  final bool isLocked;
  final bool isVisible;

  const SelectionIdentity({
    required this.title,
    required this.typeLabel,
    required this.type,
    required this.isLocked,
    required this.isVisible,
  });

  String get stateLabel {
    if (!isVisible) return 'Hidden';
    if (isLocked) return 'Locked';
    return 'Editable';
  }
}
