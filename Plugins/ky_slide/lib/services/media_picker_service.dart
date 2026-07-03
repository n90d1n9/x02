import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Image bytes and metadata selected from a local media picker.
class PickedImageMedia {
  final Uint8List bytes;
  final String? fileName;

  const PickedImageMedia({required this.bytes, this.fileName});

  String get displayName {
    final name = fileName?.trim();
    if (name == null || name.isEmpty) return 'image';

    return name;
  }
}

/// Recoverable media picking failure that can be shown in editor feedback.
class MediaPickerException implements Exception {
  final String message;

  const MediaPickerException(this.message);

  @override
  String toString() => message;
}

/// Boundary for selecting local media before converting it into slide objects.
abstract class MediaPickerService {
  Future<PickedImageMedia?> pickImage();
}

/// File picker implementation for selecting image bytes from the host system.
class FilePickerMediaPickerService implements MediaPickerService {
  const FilePickerMediaPickerService();

  @override
  Future<PickedImageMedia?> pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const MediaPickerException('Selected image could not be loaded.');
    }

    return PickedImageMedia(bytes: bytes, fileName: file.name);
  }
}
