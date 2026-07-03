import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';
import 'package:ky_docs/docx/widgets/page_navigation/document_page_navigation_model.dart';

void main() {
  group('DocumentPageNavigationModel', () {
    test('normalizes page counts and selected page labels', () {
      const model = DocumentPageNavigationModel(
        currentPage: 99,
        totalPages: 3,
        pageSettings: PageSettings(),
      );

      expect(model.pageCount, 3);
      expect(model.selectedPage, 3);
      expect(model.countLabel, '3 pages');
      expect(model.selectedPageLabel, 'Page 3 of 3');
      expect(model.itemForPage(99).pageNumber, 3);
      expect(model.itemForPage(3).selected, isTrue);
    });

    test('exposes previous and next page availability', () {
      const firstPage = DocumentPageNavigationModel(
        currentPage: 1,
        totalPages: 3,
        pageSettings: PageSettings(),
      );
      const middlePage = DocumentPageNavigationModel(
        currentPage: 2,
        totalPages: 3,
        pageSettings: PageSettings(),
      );
      const lastPage = DocumentPageNavigationModel(
        currentPage: 3,
        totalPages: 3,
        pageSettings: PageSettings(),
      );

      expect(firstPage.canGoToPreviousPage, isFalse);
      expect(firstPage.canGoToNextPage, isTrue);
      expect(firstPage.canGoToFirstPage, isFalse);
      expect(firstPage.canGoToLastPage, isTrue);
      expect(firstPage.firstPage, 1);
      expect(firstPage.previousPage, 1);
      expect(firstPage.nextPage, 2);
      expect(firstPage.lastPage, 3);

      expect(middlePage.canGoToPreviousPage, isTrue);
      expect(middlePage.canGoToNextPage, isTrue);
      expect(middlePage.canGoToFirstPage, isTrue);
      expect(middlePage.canGoToLastPage, isTrue);
      expect(middlePage.firstPage, 1);
      expect(middlePage.previousPage, 1);
      expect(middlePage.nextPage, 3);
      expect(middlePage.lastPage, 3);

      expect(lastPage.canGoToPreviousPage, isTrue);
      expect(lastPage.canGoToNextPage, isFalse);
      expect(lastPage.canGoToFirstPage, isTrue);
      expect(lastPage.canGoToLastPage, isFalse);
      expect(lastPage.firstPage, 1);
      expect(lastPage.previousPage, 2);
      expect(lastPage.nextPage, 3);
      expect(lastPage.lastPage, 3);
    });

    test('calculates selected page list offsets from tile extent', () {
      const model = DocumentPageNavigationModel(
        currentPage: 3,
        totalPages: 5,
        pageSettings: PageSettings(),
      );

      expect(model.selectedPageScrollOffset(pageTileExtent: 212), 424);
    });

    test('describes page format from size and orientation', () {
      const model = DocumentPageNavigationModel(
        currentPage: 1,
        totalPages: 1,
        pageSettings: PageSettings(
          pageSize: PageSize.letter,
          orientation: DocumentPageOrientation.landscape,
        ),
      );

      expect(model.countLabel, '1 page');
      expect(model.formatLabel, 'Letter landscape');
      expect(model.itemForPage(1).semanticLabel, contains('current page'));
    });

    test('parses page jump input into bounded page numbers', () {
      const model = DocumentPageNavigationModel(
        currentPage: 1,
        totalPages: 4,
        pageSettings: PageSettings(),
      );

      expect(model.jumpRangeLabel, '1-4');
      expect(model.pageForInput('3'), 3);
      expect(model.pageForInput(' 99 '), 4);
      expect(model.pageForInput('0'), 1);
      expect(model.pageForInput(''), isNull);
      expect(model.pageForInput('draft'), isNull);
    });
  });
}
