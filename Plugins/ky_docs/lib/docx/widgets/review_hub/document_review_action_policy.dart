import '../../models/document_editing_mode.dart';

/// Defines which review actions are available for the active editing mode.
class DocumentReviewActionPolicy {
  final DocumentEditingMode editingMode;

  const DocumentReviewActionPolicy({required this.editingMode});

  /// Default policy for fully editable review panels.
  static const editing = DocumentReviewActionPolicy(
    editingMode: DocumentEditingMode.editing,
  );

  bool get canMutateReviewItems {
    return editingMode != DocumentEditingMode.viewing;
  }

  bool get canCreateComments {
    return canMutateReviewItems;
  }

  bool get canManageComments {
    return canMutateReviewItems;
  }

  bool get canProposeChanges {
    return canMutateReviewItems;
  }

  bool get canManageTrackedChanges {
    return canMutateReviewItems;
  }

  bool get showsLockedNotice {
    return !canMutateReviewItems;
  }

  String get lockedReviewReason {
    return 'Switch to Editing or Suggesting mode to change review items';
  }
}
