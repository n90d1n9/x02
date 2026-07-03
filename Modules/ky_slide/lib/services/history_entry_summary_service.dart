import '../models/history_entry.dart';
import '../models/presentation.dart';

class HistoryEntrySummaryService {
  const HistoryEntrySummaryService._();

  static String describe(HistoryEntry entry) {
    final presentation = entry.presentation;
    final slideCount = presentation.slides.length;
    if (slideCount == 0) {
      return 'No slides';
    }

    final selectedIndex = _selectedSlideIndex(presentation);
    final selectedSlide = presentation.slides[selectedIndex];
    final title = selectedSlide.title?.trim();
    final safeTitle = title == null || title.isEmpty ? 'Untitled slide' : title;
    final slideLabel = slideCount == 1 ? '1 slide' : '$slideCount slides';

    return '$slideLabel - Slide ${selectedIndex + 1}/$slideCount: $safeTitle';
  }

  static int _selectedSlideIndex(Presentation presentation) {
    final lastIndex = presentation.slides.length - 1;
    final index = presentation.currentSlideIndex;

    if (index < 0) {
      return 0;
    }
    if (index > lastIndex) {
      return lastIndex;
    }

    return index;
  }
}
