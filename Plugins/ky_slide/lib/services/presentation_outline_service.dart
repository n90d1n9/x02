import '../models/presentation.dart';
import '../models/presentation_outline.dart';
import '../models/rich_text_content.dart';

class PresentationOutlineService {
  const PresentationOutlineService._();

  static List<SlideOutlineItem> build(Presentation presentation) {
    return [
      for (var index = 0; index < presentation.slides.length; index++)
        SlideOutlineItem(
          index: index,
          slideId: presentation.slides[index].id,
          title: _titleFor(presentation, index),
          snippet: _snippetFor(
            presentation.slides[index].components
                .map((component) => component.richText)
                .whereType<RichTextContent>()
                .map((richText) => richText.text),
          ),
          componentCount: presentation.slides[index].components.length,
        ),
    ];
  }

  static List<SlideOutlineItem> filter(
    List<SlideOutlineItem> outline,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return outline;
    }

    return outline
        .where((item) => _matchesQuery(item, normalizedQuery))
        .toList(growable: false);
  }

  static String _titleFor(Presentation presentation, int index) {
    final slide = presentation.slides[index];
    final explicitTitle = slide.title?.trim();
    if (explicitTitle != null && explicitTitle.isNotEmpty) {
      return explicitTitle;
    }

    final firstText = slide.components
        .map((component) => component.richText?.text.trim())
        .whereType<String>()
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');

    if (firstText.isNotEmpty) {
      return _compact(firstText, maxLength: 44);
    }

    return 'Slide ${index + 1}';
  }

  static String _snippetFor(Iterable<String> textBlocks) {
    final text = textBlocks
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .skip(1)
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => textBlocks
              .map((value) => value.trim())
              .firstWhere((value) => value.isNotEmpty, orElse: () => ''),
        );

    if (text.isEmpty) return 'No text content yet';

    return _compact(text, maxLength: 72);
  }

  static String _compact(String value, {required int maxLength}) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= maxLength) return collapsed;

    return '${collapsed.substring(0, maxLength - 1).trimRight()}...';
  }

  static bool _matchesQuery(SlideOutlineItem item, String query) {
    final slideNumber = '${item.index + 1}';

    return item.title.toLowerCase().contains(query) ||
        item.snippet.toLowerCase().contains(query) ||
        slideNumber == query;
  }
}
