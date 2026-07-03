import '../models/document_change.dart';

typedef DocumentTrackChangesClock = DateTime Function();

/// Builds and resolves immutable tracked-change suggestions.
class DocumentTrackChangesService {
  final DocumentTrackChangesClock now;

  const DocumentTrackChangesService({this.now = DateTime.now});

  List<DocumentChange> proposeChange({
    required List<DocumentChange> currentChanges,
    required String id,
    required String userId,
    required String userName,
    required int offset,
    required String originalText,
    required String replacementText,
    DateTime? timestamp,
  }) {
    final normalizedReplacement = replacementText.trim();
    if (normalizedReplacement.isEmpty) return currentChanges;
    if (originalText == normalizedReplacement) return currentChanges;

    return [
      ...currentChanges,
      DocumentChange(
        id: id,
        userId: userId,
        userName: userName,
        changeType: originalText.isEmpty ? 'insert' : 'replace',
        offset: offset < 0 ? 0 : offset,
        length: originalText.length,
        data: normalizedReplacement,
        originalText: originalText.isEmpty ? null : originalText,
        timestamp: timestamp ?? now(),
      ),
    ];
  }

  List<DocumentChange> acceptChange({
    required List<DocumentChange> currentChanges,
    required String id,
  }) {
    return _setStatus(
      currentChanges: currentChanges,
      id: id,
      status: DocumentChangeStatus.accepted,
    );
  }

  List<DocumentChange> rejectChange({
    required List<DocumentChange> currentChanges,
    required String id,
  }) {
    return _setStatus(
      currentChanges: currentChanges,
      id: id,
      status: DocumentChangeStatus.rejected,
    );
  }

  List<DocumentChange> deleteChange({
    required List<DocumentChange> currentChanges,
    required String id,
  }) {
    if (!currentChanges.any((change) => change.id == id)) {
      return currentChanges;
    }
    return currentChanges.where((change) => change.id != id).toList();
  }

  DocumentChange? findPendingChange({
    required List<DocumentChange> currentChanges,
    required String id,
  }) {
    for (final change in currentChanges) {
      if (change.id == id && change.isPending) return change;
    }
    return null;
  }

  List<DocumentChange> _setStatus({
    required List<DocumentChange> currentChanges,
    required String id,
    required DocumentChangeStatus status,
  }) {
    if (!currentChanges.any((change) => change.id == id)) {
      return currentChanges;
    }
    return currentChanges.map((change) {
      if (change.id != id) return change;
      return change.copyWith(status: status);
    }).toList();
  }
}
