import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_review_action_policy.dart';

void main() {
  group('DocumentReviewActionPolicy', () {
    test('allows review mutations while editing or suggesting', () {
      for (final mode in [
        DocumentEditingMode.editing,
        DocumentEditingMode.suggesting,
      ]) {
        final policy = DocumentReviewActionPolicy(editingMode: mode);

        expect(policy.canCreateComments, isTrue);
        expect(policy.canManageComments, isTrue);
        expect(policy.canProposeChanges, isTrue);
        expect(policy.canManageTrackedChanges, isTrue);
        expect(policy.showsLockedNotice, isFalse);
      }
    });

    test('locks review mutations while viewing', () {
      final policy = DocumentReviewActionPolicy(
        editingMode: DocumentEditingMode.viewing,
      );

      expect(policy.canCreateComments, isFalse);
      expect(policy.canManageComments, isFalse);
      expect(policy.canProposeChanges, isFalse);
      expect(policy.canManageTrackedChanges, isFalse);
      expect(policy.showsLockedNotice, isTrue);
      expect(policy.lockedReviewReason, contains('Editing or Suggesting'));
    });
  });
}
