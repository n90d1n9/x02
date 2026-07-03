import 'package:flutter/material.dart';
import 'package:ky_docs/compat/flutter_quill_compat.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/document_ruler.dart';
import '../../states/docs_provider.dart';
import '../../states/layout_provider.dart';
import 'slash_menu_content.dart';

class SlashCommandEditor extends ConsumerStatefulWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  const SlashCommandEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  @override
  ConsumerState<SlashCommandEditor> createState() => _SlashCommandEditorState();
}

class _SlashCommandEditorState extends ConsumerState<SlashCommandEditor> {
  OverlayEntry? _overlayEntry;
  String _searchQuery = '';

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();

    // old
    // widget.controller.removeListener(_onTextChanged);
    //_removeOverlay();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.document.toPlainText();
    final selection = widget.controller.selection;

    if (selection.baseOffset > 0) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      final lastLine = beforeCursor.split('\n').last;

      if (lastLine.startsWith('/')) {
        _searchQuery = lastLine.substring(1);
        _showSlashMenu();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showSlashMenu() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: MediaQuery.of(context).size.width / 2 - 200,
        top: 200,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: SlashMenuContent(
              query: _searchQuery,
              onSelect: _handleBlockSelection,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleBlockSelection(String blockType) {
    final selection = widget.controller.selection;
    final text = widget.controller.document.toPlainText();
    final beforeCursor = text.substring(0, selection.baseOffset);
    final lastLineStart = beforeCursor.lastIndexOf('\n') + 1;

    widget.controller.replaceText(
      lastLineStart,
      selection.baseOffset - lastLineStart,
      '',
      TextSelection.collapsed(offset: lastLineStart),
    );

    ref.read(documentControllerProvider.notifier).insertBlock(blockType);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final layoutMode = ref.watch(layoutModeProvider);
    final showRuler = ref.watch(rulerVisibilityProvider);

    return Column(
      children: [
        // Ruler
        if (showRuler && layoutMode != LayoutMode.focus)
          Consumer(
            builder: (context, ref, child) {
              return Row(
                children: [
                  const SizedBox(width: 24), // Offset for centering
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: layoutMode == LayoutMode.print ? 816 : 800,
                        ),
                        child: DocumentRuler(
                          pageWidth: layoutMode == LayoutMode.print ? 816 : 800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              );
            },
          ),
        // Editor
        Expanded(child: _buildEditorForLayout(context, layoutMode)),
      ],
    );
  }

  //---

  Widget _buildEditorForLayout(BuildContext context, LayoutMode mode) {
    switch (mode) {
      case LayoutMode.web:
        return _buildWebLayout(context);
      case LayoutMode.print:
        return _buildPrintLayout(context);
      case LayoutMode.focus:
        return _buildFocusLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Container(
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
                padding: const EdgeInsets.all(48),
                placeholder: 'Start typing or click + to insert blocks...',
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

  Widget _buildPrintLayout(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Center(
          child: Column(
            children: [
              _buildPrintPage(context, 1),
              const SizedBox(height: 24),
              // You can add more pages here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintPage(BuildContext context, int pageNumber) {
    return Container(
      width: 816, // 8.5 inches at 96 DPI
      constraints: const BoxConstraints(
        minHeight: 1056, // 11 inches at 96 DPI
      ),
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
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(72), // 0.75 inch margins
            child: quill.QuillEditor.basic(
              controller: widget.controller,
              focusNode: widget.focusNode,
              config: quill.QuillEditorConfig(
                padding: EdgeInsets.zero,
                placeholder: 'Start typing...',
                customStyles: quill.DefaultStyles(
                  placeHolder: quill.DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.4),
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
          // Page number
          Positioned(
            bottom: 24,
            right: 72,
            child: Text(
              'Page $pageNumber',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusLayout(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          child: quill.QuillEditor.basic(
            controller: widget.controller,
            focusNode: widget.focusNode,
            scrollController: widget.scrollController,
            config: quill.QuillEditorConfig(
              padding: EdgeInsets.zero,
              placeholder: 'Write without distractions...',
              customStyles: quill.DefaultStyles(
                placeHolder: quill.DefaultTextBlockStyle(
                  TextStyle(
                    fontSize: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
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
    );
  }
}
