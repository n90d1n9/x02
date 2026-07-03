class DocumentImportStructureSummary {
  final int pageCount;
  final int paragraphCount;
  final int headingCount;
  final int listItemCount;
  final int tableCount;
  final List<String> headings;
  final List<String> qualitySignals;
  final bool likelyScanned;

  const DocumentImportStructureSummary({
    required this.pageCount,
    required this.paragraphCount,
    required this.headingCount,
    required this.listItemCount,
    required this.tableCount,
    required this.headings,
    required this.qualitySignals,
    required this.likelyScanned,
  });

  const DocumentImportStructureSummary.empty()
    : pageCount = 1,
      paragraphCount = 0,
      headingCount = 0,
      listItemCount = 0,
      tableCount = 0,
      headings = const [],
      qualitySignals = const [],
      likelyScanned = false;

  String get pageLabel => pageCount == 1 ? '1 page' : '$pageCount pages';

  String get structureLabel {
    final parts = [
      if (headingCount > 0) _countLabel(headingCount, 'heading'),
      if (listItemCount > 0) _countLabel(listItemCount, 'list item'),
      if (tableCount > 0) _countLabel(tableCount, 'table'),
      if (paragraphCount > 0) _countLabel(paragraphCount, 'paragraph'),
    ];
    return parts.isEmpty ? 'No structure detected' : parts.join(', ');
  }

  bool get hasDetectedStructure {
    return headingCount > 0 ||
        listItemCount > 0 ||
        tableCount > 0 ||
        paragraphCount > 0;
  }

  static String _countLabel(int count, String label) {
    return count == 1 ? '1 $label' : '$count ${label}s';
  }
}
