import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/media_picker_service.dart';
import 'component_insert_actions_provider.dart';

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return const FilePickerMediaPickerService();
});

final mediaInsertActionsProvider = Provider<MediaInsertActions>((ref) {
  return MediaInsertActions(ref);
});

/// Coordinates media selection with slide insertion while preserving testability.
class MediaInsertActions {
  final Ref ref;

  const MediaInsertActions(this.ref);

  Future<MediaInsertResult> addImageFromPicker() async {
    try {
      final image = await ref.read(mediaPickerServiceProvider).pickImage();
      if (image == null) return const MediaInsertResult.cancelled();

      final componentId = ref
          .read(componentInsertActionsProvider)
          .addImage(image.bytes);

      return MediaInsertResult.inserted(
        componentId: componentId,
        message: 'Inserted ${image.displayName}.',
      );
    } on MediaPickerException catch (error) {
      return MediaInsertResult.failed(error.message);
    } catch (error) {
      return MediaInsertResult.failed('Error adding image: $error');
    }
  }
}

/// Status value for a media insert attempt initiated by the editor UI.
enum MediaInsertStatus { inserted, cancelled, failed }

/// User-facing outcome from a media insert workflow.
class MediaInsertResult {
  final MediaInsertStatus status;
  final String? componentId;
  final String? message;

  const MediaInsertResult._({
    required this.status,
    this.componentId,
    this.message,
  });

  const MediaInsertResult.inserted({
    required String componentId,
    required String message,
  }) : this._(
         status: MediaInsertStatus.inserted,
         componentId: componentId,
         message: message,
       );

  const MediaInsertResult.cancelled()
    : this._(status: MediaInsertStatus.cancelled);

  const MediaInsertResult.failed(String message)
    : this._(status: MediaInsertStatus.failed, message: message);
}
