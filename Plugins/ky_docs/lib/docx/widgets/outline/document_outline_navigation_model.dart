import '../../models/document_outline.dart';

/// Describes the heading level filter used by the document outline navigator.
enum DocumentOutlineLevelFilter {
  all(label: 'All', description: 'Show every heading'),
  levelOne(label: 'H1', description: 'Show top-level headings'),
  levelTwo(label: 'H2', description: 'Show second-level headings'),
  levelThreePlus(label: 'H3+', description: 'Show detailed headings');

  final String label;
  final String description;

  const DocumentOutlineLevelFilter({
    required this.label,
    required this.description,
  });

  bool accepts(int level) {
    return switch (this) {
      DocumentOutlineLevelFilter.all => true,
      DocumentOutlineLevelFilter.levelOne => level == 1,
      DocumentOutlineLevelFilter.levelTwo => level == 2,
      DocumentOutlineLevelFilter.levelThreePlus => level >= 3,
    };
  }
}

/// Builds the searchable, filterable view data for the document outline panel.
class DocumentOutlineNavigationModel {
  final List<DocumentOutline> source;
  final String query;
  final DocumentOutlineLevelFilter levelFilter;

  const DocumentOutlineNavigationModel({
    required this.source,
    this.query = '',
    this.levelFilter = DocumentOutlineLevelFilter.all,
  });

  List<DocumentOutline> get flatOutline {
    final headings = <DocumentOutline>[];
    for (final item in source) {
      _appendOutlineItem(headings, item);
    }
    return headings;
  }

  List<DocumentOutline> get visibleOutline {
    final normalizedQuery = query.trim().toLowerCase();

    return flatOutline
        .where((item) {
          final matchesLevel = levelFilter.accepts(item.level);
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.title.toLowerCase().contains(normalizedQuery);
          return matchesLevel && matchesQuery;
        })
        .toList(growable: false);
  }

  int get totalCount => flatOutline.length;

  int get visibleCount => visibleOutline.length;

  bool get hasQuery => query.trim().isNotEmpty;

  Map<DocumentOutlineLevelFilter, int> get levelCounts {
    final headings = flatOutline;
    return {
      for (final filter in DocumentOutlineLevelFilter.values)
        filter: headings.where((item) => filter.accepts(item.level)).length,
    };
  }

  void _appendOutlineItem(
    List<DocumentOutline> headings,
    DocumentOutline item,
  ) {
    headings.add(item);
    for (final child in item.children) {
      _appendOutlineItem(headings, child);
    }
  }
}
