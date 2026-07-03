import 'package:flutter_riverpod/legacy.dart';

import '../models/transform_feedback.dart';

/// Active measurement feedback shown while an object is being transformed.
final transformFeedbackProvider = StateProvider<TransformFeedback?>((ref) {
  return null;
});
