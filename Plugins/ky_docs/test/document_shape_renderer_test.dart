import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_shape_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentShapeRenderer', () {
    const renderer = DocumentShapeRenderer();

    test('reports supported shape types', () {
      expect(renderer.supports('rectangle'), isTrue);
      expect(renderer.supports('circle'), isTrue);
      expect(renderer.supports('triangle'), isTrue);
      expect(renderer.supports('star'), isTrue);
      expect(renderer.supports('hexagon'), isFalse);
    });

    test('renders supported shapes as png images', () async {
      for (final shapeType in DocumentShapeRenderer.supportedShapeTypes) {
        final shape = await renderer.renderPng(shapeType, size: 32);

        expect(shape, isNotNull);
        expect(shape!.width, 32);
        expect(shape.height, 32);
        expect(shape.imageBytes.take(8).toList(), [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ]);
      }
    });

    test('returns null for unsupported shapes and invalid size', () async {
      expect(await renderer.renderPng('hexagon'), isNull);
      expect(await renderer.renderPng('rectangle', size: 0), isNull);
    });
  });
}
