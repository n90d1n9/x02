import 'package:file_picker/file_picker.dart';

typedef DocumentImagePicker = Future<PickedDocumentImage?> Function();

class PickedDocumentImage {
  final String name;
  final String path;

  const PickedDocumentImage({required this.name, required this.path});
}

class DocumentImageInsertion {
  final String name;
  final String path;
  final String referenceText;

  const DocumentImageInsertion({
    required this.name,
    required this.path,
    required this.referenceText,
  });
}

class DocumentImageInsertionService {
  final DocumentImagePicker imagePicker;

  const DocumentImageInsertionService({this.imagePicker = pickDocumentImage});

  Future<DocumentImageInsertion?> pickImage() async {
    final image = await imagePicker();
    if (image == null) return null;

    return DocumentImageInsertion(
      name: image.name,
      path: image.path,
      referenceText: placeholderFor(image.name),
    );
  }

  String placeholderFor(String imageName) {
    return '\n[Image: $imageName]\n';
  }
}

Future<PickedDocumentImage?> pickDocumentImage() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  final file = result?.files.single;
  final path = file?.path;
  if (file == null || path == null) return null;

  return PickedDocumentImage(name: file.name, path: path);
}
