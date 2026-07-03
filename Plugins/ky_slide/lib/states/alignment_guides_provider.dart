import 'package:flutter_riverpod/legacy.dart';

import '../models/alignment_guide.dart';

/// Active smart alignment guides shown while an object is being moved or resized.
final alignmentGuidesProvider = StateProvider<List<AlignmentGuide>>((ref) {
  return const [];
});
