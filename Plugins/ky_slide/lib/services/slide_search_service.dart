import '../models/presentation.dart';
import '../models/slide.dart';

class SlideSearchService {
  const SlideSearchService._();

  static List<int> matchingIndexes(Presentation presentation, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return [
        for (var index = 0; index < presentation.slides.length; index++) index,
      ];
    }

    return [
      for (var index = 0; index < presentation.slides.length; index++)
        if (_matchesSlide(presentation.slides[index], index, normalizedQuery))
          index,
    ];
  }

  static bool _matchesSlide(Slide slide, int index, String query) {
    final slideNumber = '${index + 1}';
    final title = slide.title ?? '';
    final notes = slide.notes ?? '';
    final componentText = slide.components
        .map((component) => component.richText?.text ?? '')
        .join(' ');

    return slideNumber == query ||
        title.toLowerCase().contains(query) ||
        notes.toLowerCase().contains(query) ||
        componentText.toLowerCase().contains(query);
  }
}
