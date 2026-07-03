/// Review lifecycle for a tracked document change.
enum DocumentChangeStatus { pending, accepted, rejected }

/// A tracked edit suggestion or collaboration change anchored to document text.
class DocumentChange {
  final String id;
  final String userId;
  final String userName;
  final String changeType;
  final int offset;
  final int length;
  final String? data;
  final String? originalText;
  final DateTime timestamp;
  final DocumentChangeStatus status;

  DocumentChange({
    this.id = '',
    required this.userId,
    String? userName,
    required this.changeType,
    required this.offset,
    this.length = 0,
    this.data,
    this.originalText,
    required this.timestamp,
    this.status = DocumentChangeStatus.pending,
  }) : userName = userName ?? userId;

  bool get isPending => status == DocumentChangeStatus.pending;

  bool get isResolved => status != DocumentChangeStatus.pending;

  bool get isInsertion => changeType == 'insert';

  bool get isReplacement => changeType == 'replace';

  String get replacementText => data ?? '';

  DocumentChange copyWith({
    String? id,
    String? userId,
    String? userName,
    String? changeType,
    int? offset,
    int? length,
    String? data,
    String? originalText,
    DateTime? timestamp,
    DocumentChangeStatus? status,
  }) {
    return DocumentChange(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      changeType: changeType ?? this.changeType,
      offset: offset ?? this.offset,
      length: length ?? this.length,
      data: data ?? this.data,
      originalText: originalText ?? this.originalText,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'changeType': changeType,
    'offset': offset,
    'length': length,
    'data': data,
    'originalText': originalText,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
  };

  factory DocumentChange.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.parse(json['timestamp']);
    final userId = json['userId'] ?? 'unknown';
    final offset = json['offset'] ?? 0;

    return DocumentChange(
      id: json['id'] ?? '$userId-${timestamp.toIso8601String()}-$offset',
      userId: userId,
      userName: json['userName'] ?? userId,
      changeType: json['changeType'],
      offset: offset,
      length: json['length'] ?? (json['originalText'] as String?)?.length ?? 0,
      data: json['data'],
      originalText: json['originalText'],
      timestamp: timestamp,
      status: _statusFromJson(json['status']),
    );
  }

  static DocumentChangeStatus _statusFromJson(Object? status) {
    if (status is! String) return DocumentChangeStatus.pending;
    return DocumentChangeStatus.values.firstWhere(
      (value) => value.name == status,
      orElse: () => DocumentChangeStatus.pending,
    );
  }
}
