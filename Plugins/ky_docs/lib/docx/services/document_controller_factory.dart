import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as d;

import 'waraq_quill_document_mapper.dart';

class DocumentControllerFactory {
  final WaraqQuillDocumentMapper waraqMapper;

  const DocumentControllerFactory({
    this.waraqMapper = const WaraqQuillDocumentMapper(),
  });

  quill.QuillController createBlank() {
    return quill.QuillController.basic();
  }

  quill.QuillController createFromPlainText(String text) {
    final controller = createBlank();
    if (text.isNotEmpty) {
      controller.document.insert(0, text);
    }
    return controller;
  }

  quill.QuillController createFromDeltaJson(String content) {
    final delta = d.Delta.fromJson(jsonDecode(content));
    return createFromDelta(delta);
  }

  quill.QuillController createFromWaraqDocsEngineJson(String content) {
    return _controllerFor(waraqMapper.fromDocsEngineJson(content));
  }

  quill.QuillController createFromDelta(d.Delta delta) {
    return _controllerFor(quill.Document.fromDelta(delta));
  }

  quill.QuillController _controllerFor(quill.Document document) {
    return quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  String encodeDelta(quill.QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }
}
