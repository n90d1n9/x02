import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/layout_provider.dart';
import '../widgets/widgets/document_ruler_system.dart';

class EnhancedEditorWithRuler extends ConsumerStatefulWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  const EnhancedEditorWithRuler({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  @override
  ConsumerState<EnhancedEditorWithRuler> createState() =>
      _EnhancedEditorWithRulerState();
}

class _EnhancedEditorWithRulerState
    extends ConsumerState<EnhancedEditorWithRuler> {
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCursorPosition);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCursorPosition);
    super.dispose();
  }

  void _updateCursorPosition() {
    // This would be more accurate with actual cursor position from editor
    // For now, we'll estimate based on selection
    final selection = widget.controller.selection;
    if (selection.isValid && _editorKey.currentContext != null) {
      // Approximate cursor position (in a real implementation,
      // you'd get this from the RenderObject)
      final renderBox =
          _editorKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        // Estimate position (this is simplified)
        final offset = Offset(
          100.0, // X position (would need actual calculation)
          50.0 + (selection.baseOffset * 0.5), // Y position estimate
        );
        ref.read(cursorPositionProvider.notifier).state = offset;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutMode = ref.watch(layoutModeProvider);

    return DocumentRulerSystem(
      pageWidth: layoutMode == LayoutMode.print ? 816 : 800,
      pageHeight: layoutMode == LayoutMode.print ? 1056 : 2000,
      scrollController: widget.scrollController,
      child: _buildEditor(context, layoutMode),
    );
  }

  Widget _buildEditor(BuildContext context, LayoutMode mode) {
    if (mode == LayoutMode.print) {
      return _buildPrintLayout();
    } else {
      return _buildWebLayout();
    }
  }

  Widget _buildWebLayout() {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          key: _editorKey,
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: quill.QuillEditor.basic(
              controller: widget.controller,
              focusNode: widget.focusNode,
              scrollController: widget.scrollController,
              config: quill.QuillEditorConfig(
                padding: const EdgeInsets.all(72),
                placeholder: 'Start typing or click "Insert" to add content...',
                customStyles: quill.DefaultStyles(
                  placeHolder: quill.DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const quill.HorizontalSpacing(0, 0),
                    const quill.VerticalSpacing(0, 0),
                    const quill.VerticalSpacing(0, 0),
                    BoxDecoration(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrintLayout() {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Center(
          child: Container(
            key: _editorKey,
            width: 816,
            constraints: const BoxConstraints(minHeight: 1056),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(72),
              child: quill.QuillEditor.basic(
                controller: widget.controller,
                focusNode: widget.focusNode,
                config: quill.QuillEditorConfig(
                  padding: EdgeInsets.zero,
                  placeholder: 'Start typing...',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
