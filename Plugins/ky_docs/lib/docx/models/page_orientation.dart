import 'package:flutter/material.dart';

/// Describes whether a page is laid out vertically or horizontally.
enum DocumentPageOrientation { portrait, landscape }

/// Provides labels and icons for page orientation controls.
extension DocumentPageOrientationDetails on DocumentPageOrientation {
  String get label {
    return switch (this) {
      DocumentPageOrientation.portrait => 'Portrait',
      DocumentPageOrientation.landscape => 'Landscape',
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentPageOrientation.portrait => Icons.stay_current_portrait,
      DocumentPageOrientation.landscape => Icons.stay_current_landscape,
    };
  }
}
