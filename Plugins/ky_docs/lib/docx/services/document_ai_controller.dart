import '../models/aiaction.dart';

typedef AiTextProcessor = Future<String> Function(String text, AIAction action);

class AiTextRange {
  final int start;
  final int end;

  const AiTextRange({required this.start, required this.end});

  bool get isCollapsed => start == end;
  int get length => end - start;

  String slice(String text) => text.substring(start, end);
}

class AiReplacementPlan {
  final int start;
  final int length;
  final int cursorOffset;

  const AiReplacementPlan({
    required this.start,
    required this.length,
    required this.cursorOffset,
  });
}

class DocumentAiController {
  final AiTextProcessor processText;

  const DocumentAiController({required this.processText});

  Future<String> processAction({
    required String documentText,
    required int selectionBaseOffset,
    required int selectionExtentOffset,
    required AIAction action,
  }) {
    final textToProcess = textForProcessing(
      documentText: documentText,
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
    );

    return processText(textToProcess, action);
  }

  String textForProcessing({
    required String documentText,
    required int selectionBaseOffset,
    required int selectionExtentOffset,
  }) {
    final range = selectedTextRange(
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      textLength: documentText.length,
    );

    if (!range.isCollapsed) return range.slice(documentText);
    if (documentText.trim().isEmpty) {
      throw Exception('No text to process');
    }

    return documentText;
  }

  AiReplacementPlan replacementPlan({
    required int selectionBaseOffset,
    required int selectionExtentOffset,
    required int documentLength,
    required String result,
  }) {
    final editableLength = _editableDocumentLength(documentLength);
    final range = selectedTextRange(
      selectionBaseOffset: selectionBaseOffset,
      selectionExtentOffset: selectionExtentOffset,
      textLength: editableLength,
    );

    if (!range.isCollapsed) {
      return AiReplacementPlan(
        start: range.start,
        length: range.length,
        cursorOffset: range.start + result.length,
      );
    }

    return AiReplacementPlan(
      start: 0,
      length: editableLength,
      cursorOffset: result.length,
    );
  }

  AiTextRange selectedTextRange({
    required int selectionBaseOffset,
    required int selectionExtentOffset,
    required int textLength,
  }) {
    final start = _clampOffset(
      selectionBaseOffset < selectionExtentOffset
          ? selectionBaseOffset
          : selectionExtentOffset,
      textLength,
    );
    final end = _clampOffset(
      selectionBaseOffset > selectionExtentOffset
          ? selectionBaseOffset
          : selectionExtentOffset,
      textLength,
    );

    return AiTextRange(start: start, end: end);
  }

  String insertionText(String result) => '\n\n$result\n\n';

  int _editableDocumentLength(int documentLength) {
    return documentLength <= 0 ? 0 : documentLength - 1;
  }

  int _clampOffset(int offset, int textLength) {
    if (offset < 0) return 0;
    if (offset > textLength) return textLength;
    return offset;
  }
}
