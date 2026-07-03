import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/selection_toolbar/document_selection_toolbar_policy.dart';

void main() {
  group('DocumentSelectionToolbarPolicy', () {
    test('keeps editing and suggesting action-rich', () {
      const editing = DocumentSelectionToolbarPolicy(
        editingMode: DocumentEditingMode.editing,
      );
      const suggesting = DocumentSelectionToolbarPolicy(
        editingMode: DocumentEditingMode.suggesting,
      );

      expect(editing.showsFormattingActions, isTrue);
      expect(editing.showsReviewActions, isTrue);
      expect(editing.showsModeBadge, isFalse);
      expect(suggesting.showsFormattingActions, isTrue);
      expect(suggesting.showsReviewActions, isTrue);
      expect(suggesting.showsModeBadge, isTrue);
    });

    test('locks mutating selection actions in viewing mode', () {
      const policy = DocumentSelectionToolbarPolicy(
        editingMode: DocumentEditingMode.viewing,
      );

      expect(policy.showsFormattingActions, isFalse);
      expect(policy.showsReviewActions, isFalse);
      expect(policy.showsModeBadge, isTrue);
      expect(policy.modeLabel, 'Viewing');
    });
  });
}
