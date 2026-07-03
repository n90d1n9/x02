import 'package:flutter_riverpod/legacy.dart';

import '../../docx/models/attachment.dart';

final attachmentsProvider =
    StateNotifierProvider<AttachmentsNotifier, List<Attachment>>((ref) {
      return AttachmentsNotifier();
    });

class AttachmentsNotifier extends StateNotifier<List<Attachment>> {
  AttachmentsNotifier() : super([]);

  void addAttachment(String name, String type, int size) {
    final attachment = Attachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      size: size,
      uploadedAt: DateTime.now(),
      url: 'https://example.com/files/${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [...state, attachment];
  }

  void removeAttachment(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}
