import 'alignment_guide.dart';
import 'presentation_component.dart';

/// Result of applying smart alignment snapping to a preview component frame.
class AlignmentSnapResult {
  final PresentationComponent component;
  final List<AlignmentGuide> guides;

  const AlignmentSnapResult({required this.component, required this.guides});
}
