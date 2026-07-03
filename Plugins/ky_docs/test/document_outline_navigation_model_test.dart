import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_outline.dart';
import 'package:ky_docs/docx/widgets/outline/document_outline_navigation_model.dart';

void main() {
  group('DocumentOutlineNavigationModel', () {
    test('flattens nested headings and reports level counts', () {
      final model = DocumentOutlineNavigationModel(source: _outlineFixture());

      expect(model.totalCount, 5);
      expect(model.levelCounts[DocumentOutlineLevelFilter.levelOne], 2);
      expect(model.levelCounts[DocumentOutlineLevelFilter.levelTwo], 2);
      expect(model.levelCounts[DocumentOutlineLevelFilter.levelThreePlus], 1);
    });

    test('filters headings by query and level', () {
      final model = DocumentOutlineNavigationModel(
        source: _outlineFixture(),
        query: 'api',
        levelFilter: DocumentOutlineLevelFilter.levelThreePlus,
      );

      expect(model.visibleCount, 1);
      expect(model.visibleOutline.single.title, 'API Appendix');
      expect(model.hasQuery, isTrue);
    });
  });
}

List<DocumentOutline> _outlineFixture() {
  return const [
    DocumentOutline(
      id: 'overview',
      title: 'Overview',
      level: 1,
      offset: 0,
      children: [
        DocumentOutline(id: 'goals', title: 'Goals', level: 2, offset: 12),
        DocumentOutline(id: 'api', title: 'API Appendix', level: 3, offset: 28),
      ],
    ),
    DocumentOutline(
      id: 'pricing',
      title: 'Pricing',
      level: 1,
      offset: 48,
      children: [
        DocumentOutline(
          id: 'enterprise',
          title: 'Enterprise Plans',
          level: 2,
          offset: 64,
        ),
      ],
    ),
  ];
}
