import 'package:flutter/widgets.dart';

import '../../models/page_orientation.dart';
import '../../models/page_settings.dart';
import '../../models/page_size.dart';

/// Describes the page list shown by the document page navigator rail.
class DocumentPageNavigationModel {
  final int currentPage;
  final int totalPages;
  final PageSettings pageSettings;

  const DocumentPageNavigationModel({
    required this.currentPage,
    required this.totalPages,
    required this.pageSettings,
  });

  int get pageCount => totalPages.clamp(1, 9999).toInt();

  int get selectedPage => currentPage.clamp(1, pageCount).toInt();

  bool get canGoToFirstPage => selectedPage > 1;

  bool get canGoToPreviousPage => selectedPage > 1;

  bool get canGoToNextPage => selectedPage < pageCount;

  bool get canGoToLastPage => selectedPage < pageCount;

  int get firstPage => 1;

  int get previousPage => (selectedPage - 1).clamp(1, pageCount).toInt();

  int get nextPage => (selectedPage + 1).clamp(1, pageCount).toInt();

  int get lastPage => pageCount;

  Size get pageSize => pageSettings.getPageSize();

  String get countLabel => pageCount == 1 ? '1 page' : '$pageCount pages';

  String get selectedPageLabel => 'Page $selectedPage of $pageCount';

  String get jumpRangeLabel => '1-$pageCount';

  String get formatLabel =>
      '${pageSettings.pageSize.label} '
      '${pageSettings.orientation.label.toLowerCase()}';

  DocumentPageNavigationItem itemForPage(int pageNumber) {
    final normalizedPage = pageNumber.clamp(1, pageCount).toInt();
    return DocumentPageNavigationItem(
      pageNumber: normalizedPage,
      pageSize: pageSize,
      formatLabel: formatLabel,
      selected: normalizedPage == selectedPage,
    );
  }

  /// Returns the list offset that places the selected page at the top.
  double selectedPageScrollOffset({required double pageTileExtent}) {
    assert(pageTileExtent > 0, 'Page tile extent must be positive.');
    return (selectedPage - 1) * pageTileExtent;
  }

  int? pageForInput(String input) {
    final pageNumber = int.tryParse(input.trim());
    if (pageNumber == null) return null;
    return pageNumber.clamp(1, pageCount).toInt();
  }
}

/// Represents one selectable thumbnail entry in the page navigator rail.
class DocumentPageNavigationItem {
  final int pageNumber;
  final Size pageSize;
  final String formatLabel;
  final bool selected;

  const DocumentPageNavigationItem({
    required this.pageNumber,
    required this.pageSize,
    required this.formatLabel,
    required this.selected,
  });

  String get pageLabel => 'Page $pageNumber';

  String get semanticLabel {
    if (selected) return '$pageLabel, current page, $formatLabel';
    return '$pageLabel, $formatLabel';
  }
}
