import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';

void main() {
  group('PageSettings', () {
    test('uses portrait page dimensions by default', () {
      final size = const PageSettings(pageSize: PageSize.letter).getPageSize();

      expect(size.width, 612);
      expect(size.height, 792);
    });

    test('swaps page dimensions in landscape orientation', () {
      final size = const PageSettings(
        pageSize: PageSize.letter,
        orientation: DocumentPageOrientation.landscape,
      ).getPageSize();

      expect(size.width, 792);
      expect(size.height, 612);
    });

    test('copies orientation with other page settings', () {
      final settings = const PageSettings().copyWith(
        pageSize: PageSize.legal,
        orientation: DocumentPageOrientation.landscape,
      );

      expect(settings.pageSize, PageSize.legal);
      expect(settings.orientation, DocumentPageOrientation.landscape);
    });
  });
}
