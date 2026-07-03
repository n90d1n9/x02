import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class PptxPartRelationship {
  final String id;
  final String type;
  final String target;

  const PptxPartRelationship({
    required this.id,
    required this.type,
    required this.target,
  });

  bool get isNotesSlide => type.endsWith('/notesSlide');
}

class PptxRelationshipReader {
  const PptxRelationshipReader();

  List<PptxPartRelationship> forPart(Archive archive, String partPath) {
    final relsPath = pathForPart(partPath);
    final file = archive.findFile(relsPath);
    if (file == null) return const [];

    final document = XmlDocument.parse(String.fromCharCodes(file.content));
    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'Relationship')
        .map((element) {
          final id = element.getAttribute('Id');
          final type = element.getAttribute('Type');
          final target = element.getAttribute('Target');
          if (id == null || type == null || target == null) return null;

          return PptxPartRelationship(id: id, type: type, target: target);
        })
        .nonNulls
        .toList(growable: false);
  }

  Map<String, String> targetsById(List<PptxPartRelationship> relationships) {
    return {
      for (final relationship in relationships)
        relationship.id: relationship.target,
    };
  }

  String pathForPart(String partPath) {
    final segments = partPath.split('/');
    final fileName = segments.removeLast();
    segments.add('_rels');
    segments.add('$fileName.rels');
    return segments.join('/');
  }
}
