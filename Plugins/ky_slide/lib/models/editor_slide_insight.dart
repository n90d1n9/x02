import 'slide.dart';

/// Derived current-slide metadata used by compact editor chrome.
class EditorSlideInsight {
  final int objectCount;
  final int hiddenObjectCount;
  final int lockedObjectCount;
  final bool hasSpeakerNotes;

  const EditorSlideInsight({
    required this.objectCount,
    required this.hiddenObjectCount,
    required this.lockedObjectCount,
    required this.hasSpeakerNotes,
  });

  factory EditorSlideInsight.fromSlide(Slide slide) {
    return EditorSlideInsight(
      objectCount: slide.components.length,
      hiddenObjectCount: slide.components
          .where((component) => !component.isVisible)
          .length,
      lockedObjectCount: slide.components
          .where((component) => component.isLocked)
          .length,
      hasSpeakerNotes: slide.notes?.trim().isNotEmpty ?? false,
    );
  }

  String get objectLabel => _pluralize(objectCount, 'object');

  String get hiddenLabel {
    if (hiddenObjectCount == 0) return 'All visible';
    return _pluralize(hiddenObjectCount, 'hidden object');
  }

  String get lockedLabel {
    if (lockedObjectCount == 0) return 'No locked objects';
    return _pluralize(lockedObjectCount, 'locked object');
  }

  String get notesLabel => hasSpeakerNotes ? 'Speaker notes' : 'No notes';

  String? get hiddenBadgeLabel {
    if (hiddenObjectCount == 0) return null;
    return '$hiddenObjectCount hidden';
  }

  String? get lockedBadgeLabel {
    if (lockedObjectCount == 0) return null;
    return '$lockedObjectCount locked';
  }

  String? get notesBadgeLabel => hasSpeakerNotes ? 'Notes' : null;

  String get tooltipLabel {
    return '$objectLabel, $hiddenLabel, $lockedLabel, $notesLabel';
  }

  static String _pluralize(int count, String noun) {
    return '$count $noun${count == 1 ? '' : 's'}';
  }
}
