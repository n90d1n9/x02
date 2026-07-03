import 'dart:typed_data';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';

class PptxSlideMedia {
  final PresentationComponent component;
  final String relationshipId;
  final String fileName;
  final Uint8List bytes;

  const PptxSlideMedia({
    required this.component,
    required this.relationshipId,
    required this.fileName,
    required this.bytes,
  });
}

class PptxSlideMediaCollector {
  const PptxSlideMediaCollector();

  List<PptxSlideMedia> collect(
    Slide slide, {
    required int firstRelationshipNumber,
    required int firstMediaIndex,
  }) {
    var relationshipNumber = firstRelationshipNumber;
    var mediaIndex = firstMediaIndex;
    final images = <PptxSlideMedia>[];

    for (final component in slide.components) {
      final bytes = component.imageData;
      if (!component.isVisible ||
          component.type != ComponentType.image ||
          bytes == null) {
        continue;
      }

      final extension = extensionFor(bytes);
      images.add(
        PptxSlideMedia(
          component: component,
          relationshipId: 'rId$relationshipNumber',
          fileName: 'image$mediaIndex.$extension',
          bytes: bytes,
        ),
      );
      relationshipNumber++;
      mediaIndex++;
    }

    return images;
  }

  String extensionFor(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }

    return 'png';
  }
}
