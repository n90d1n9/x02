import 'slide.dart';

/// Compact slide metadata shown inside status-bar jump menus.
class EditorSlideJumpSummary {
  final int index;
  final String title;
  final int? objectCount;
  final bool hasSpeakerNotes;

  const EditorSlideJumpSummary({
    required this.index,
    required this.title,
    this.objectCount,
    this.hasSpeakerNotes = false,
  });

  factory EditorSlideJumpSummary.fromSlide(Slide slide, {required int index}) {
    final trimmedTitle = slide.title?.trim();

    return EditorSlideJumpSummary(
      index: index,
      title: trimmedTitle == null || trimmedTitle.isEmpty
          ? 'Slide ${index + 1}'
          : trimmedTitle,
      objectCount: slide.components.length,
      hasSpeakerNotes: slide.notes?.trim().isNotEmpty ?? false,
    );
  }

  String get displayTitle {
    final trimmedTitle = title.trim();
    return trimmedTitle.isEmpty ? 'Slide ${index + 1}' : trimmedTitle;
  }

  String? get objectLabel {
    final count = objectCount;
    if (count == null) return null;

    return '$count ${count == 1 ? 'object' : 'objects'}';
  }
}
