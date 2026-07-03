import '../models/page_settings.dart';

class DocumentPaginationService {
  final int charactersPerLine;
  final double lineHeight;
  final int maxPages;

  const DocumentPaginationService({
    this.charactersPerLine = 80,
    this.lineHeight = 20,
    this.maxPages = 9999,
  }) : assert(charactersPerLine > 0),
       assert(lineHeight > 0),
       assert(maxPages > 0);

  int estimateTotalPages({
    required String text,
    required PageSettings pageSettings,
  }) {
    final estimatedLinesPerPage = (pageSettings.getContentHeight() / lineHeight)
        .floor();
    final linesPerPage = estimatedLinesPerPage < 1 ? 1 : estimatedLinesPerPage;
    final totalLines = (text.length / charactersPerLine).ceil();
    final pages = (totalLines / linesPerPage).ceil();

    if (pages < 1) return 1;
    if (pages > maxPages) return maxPages;
    return pages;
  }
}
