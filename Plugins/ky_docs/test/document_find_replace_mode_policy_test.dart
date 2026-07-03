import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/find_replace/find_replace_mode_policy.dart';

void main() {
  group('DocxFindReplaceModePolicy', () {
    test('keeps editing and suggesting replacement-capable', () {
      const editing = DocxFindReplaceModePolicy(
        editingMode: DocumentEditingMode.editing,
      );
      const suggesting = DocxFindReplaceModePolicy(
        editingMode: DocumentEditingMode.suggesting,
      );

      expect(editing.canReplace, isTrue);
      expect(editing.title, 'Find & Replace');
      expect(editing.commandTitle, 'Find and replace');
      expect(editing.showsModeBadge, isFalse);
      expect(suggesting.canReplace, isTrue);
      expect(suggesting.showsModeBadge, isTrue);
      expect(suggesting.modeLabel, 'Suggesting');
    });

    test('turns viewing into find-only mode', () {
      const policy = DocxFindReplaceModePolicy(
        editingMode: DocumentEditingMode.viewing,
      );

      expect(policy.canReplace, isFalse);
      expect(policy.title, 'Find');
      expect(policy.commandTitle, 'Find');
      expect(policy.modeLabel, 'Find only');
      expect(policy.modeDescription, contains('locks'));
    });
  });
}
