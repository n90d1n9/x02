import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_image_insertion_service.dart';

void main() {
  group('DocumentImageInsertionService', () {
    DocumentImageInsertionService service({PickedDocumentImage? image}) {
      return DocumentImageInsertionService(imagePicker: () async => image);
    }

    test('builds a placeholder reference for picked images', () async {
      final insertion = await service(
        image: const PickedDocumentImage(
          name: 'diagram.png',
          path: '/tmp/diagram.png',
        ),
      ).pickImage();

      expect(insertion?.name, 'diagram.png');
      expect(insertion?.path, '/tmp/diagram.png');
      expect(insertion?.referenceText, '\n[Image: diagram.png]\n');
    });

    test('returns null when image picking is cancelled', () async {
      final insertion = await service().pickImage();

      expect(insertion, isNull);
    });

    test('formats placeholder text consistently', () {
      expect(
        const DocumentImageInsertionService().placeholderFor('photo.jpg'),
        '\n[Image: photo.jpg]\n',
      );
    });
  });
}
