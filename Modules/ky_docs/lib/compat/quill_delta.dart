// Minimal Delta compatibility shim for quill deltas used across ky_docs.
class Delta {
  final List<Map<String, Object?>> ops;
  Delta([List<Map<String, Object?>>? ops]) : ops = ops ?? [];

  factory Delta.fromJson(Object? json) => Delta();
  factory Delta.fromOps(List<Map<String, Object?>> ops) => Delta(ops);

  void insert(Object data, [Map<String, Object?>? attributes]) {
    ops.add({'insert': data, if (attributes != null) 'attributes': attributes});
  }

  bool get isEmpty => ops.isEmpty;
  List<dynamic> toJson() => ops;
}
