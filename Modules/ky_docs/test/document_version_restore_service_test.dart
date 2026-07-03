import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_version.dart';
import 'package:ky_docs/docx/services/document_version_restore_service.dart';

void main() {
  group('DocumentVersionRestoreService', () {
    const service = DocumentVersionRestoreService();

    List<DocumentVersion> versions() {
      return [
        DocumentVersion(
          id: 'version-1',
          timestamp: DateTime(2026),
          content: 'first',
        ),
        DocumentVersion(
          id: 'version-2',
          timestamp: DateTime(2026, 1, 2),
          content: 'second',
        ),
      ];
    }

    test('returns a restore plan for valid version indexes', () {
      final plan = service.restorePlan(versions: versions(), index: 1);

      expect(plan?.index, 1);
      expect(plan?.version.id, 'version-2');
      expect(plan?.content, 'second');
    });

    test('returns null for invalid version indexes', () {
      expect(service.restorePlan(versions: versions(), index: -1), isNull);
      expect(service.restorePlan(versions: versions(), index: 2), isNull);
      expect(service.restorePlan(versions: const [], index: 0), isNull);
    });
  });
}
