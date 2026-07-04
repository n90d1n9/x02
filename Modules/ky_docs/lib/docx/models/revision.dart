import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';

/// Represents the type of change in a revision
enum RevisionType {
  insert,
  delete,
  format,
}

/// Represents a single change (revision) in the document
class Revision {
  final String id;
  final RevisionType type;
  final int index; // Position in the document where change occurred
  final dynamic data; // The text inserted or deleted (String or Delta attributes)
  final DateTime timestamp;
  final String authorName;
  final String? authorId;
  final bool isResolved; // Whether the change has been accepted/rejected

  Revision({
    required this.id,
    required this.type,
    required this.index,
    required this.data,
    required this.timestamp,
    required this.authorName,
    this.authorId,
    this.isResolved = false,
  });

  /// Creates a copy of this revision with updated fields
  Revision copyWith({
    String? id,
    RevisionType? type,
    int? index,
    dynamic data,
    DateTime? timestamp,
    String? authorName,
    String? authorId,
    bool? isResolved,
  }) {
    return Revision(
      id: id ?? this.id,
      type: type ?? this.type,
      index: index ?? this.index,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  /// Converts revision to a map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'index': index,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'authorName': authorName,
      'authorId': authorId,
      'isResolved': isResolved,
    };
  }

  /// Creates a revision from a map
  factory Revision.fromJson(Map<String, dynamic> json) {
    return Revision(
      id: json['id'] as String,
      type: RevisionType.values.firstWhere((e) => e.name == json['type']),
      index: json['index'] as int,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      authorName: json['authorName'] as String,
      authorId: json['authorId'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Revision(id: $id, type: $type, index: $index, author: $authorName, resolved: $isResolved)';
  }
}

/// Helper class to manage a collection of revisions
class RevisionManager {
  final List<Revision> _revisions = [];
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  List<Revision> get revisions => List.unmodifiable(_revisions);
  List<Revision> get pendingRevisions =>
      _revisions.where((r) => !r.isResolved).toList();

  void toggleTracking(bool value) {
    _isTracking = value;
  }

  void addRevision(Revision revision) {
    if (_isTracking) {
      _revisions.add(revision);
    }
  }

  void acceptRevision(String id) {
    final index = _revisions.indexWhere((r) => r.id == id);
    if (index != -1) {
      // In a real implementation, accepting an insert keeps it,
      // accepting a delete removes it permanently.
      // Here we just mark as resolved. The document content is already updated
      // in "suggestion mode" visualisation, accepting makes it permanent.
      _revisions[index] = _revisions[index].copyWith(isResolved: true);
    }
  }

  void rejectRevision(String id) {
    final index = _revisions.indexWhere((r) => r.id == id);
    if (index != -1) {
      final revision = _revisions[index];
      // Logic to revert the change would happen here in the controller
      // For now, we just mark as resolved
      _revisions[index] = _revisions[index].copyWith(isResolved: true);
    }
  }

  void acceptAll() {
    for (var i = 0; i < _revisions.length; i++) {
      _revisions[i] = _revisions[i].copyWith(isResolved: true);
    }
  }

  void rejectAll() {
    for (var i = 0; i < _revisions.length; i++) {
      _revisions[i] = _revisions[i].copyWith(isResolved: true);
    }
  }

  void clearResolved() {
    _revisions.removeWhere((r) => r.isResolved);
  }
}
