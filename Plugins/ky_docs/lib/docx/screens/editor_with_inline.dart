import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/inline_button.dart';
import '../widgets/widgets/chat_panel.dart';
import '../widgets/widgets/inline_action_button.dart';

class EditorWithInlineButtons extends ConsumerStatefulWidget {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  const EditorWithInlineButtons({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  @override
  ConsumerState<EditorWithInlineButtons> createState() =>
      _EditorWithInlineButtonsState();
}

class _EditorWithInlineButtonsState
    extends ConsumerState<EditorWithInlineButtons> {
  final GlobalKey _editorKey = GlobalKey();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _updateButtonPosition();
    } else {
      ref.read(showInlineButtonsProvider.notifier).state = false;
    }
  }

  void _onTextChanged() {
    // Debounce to avoid too frequent updates
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _updateButtonPosition();
    });
  }

  void _updateButtonPosition() {
    if (!mounted) return;

    final selection = widget.controller.selection;
    if (!selection.isValid) {
      ref.read(showInlineButtonsProvider.notifier).state = false;
      return;
    }

    // Check if line is empty (start of new line)
    final text = widget.controller.document.toPlainText();
    final offset = selection.baseOffset;

    // Check if cursor is at start of line or after newline
    bool isNewLine = offset == 0 || (offset > 0 && text[offset - 1] == '\n');

    if (isNewLine) {
      // Calculate button position
      final renderBox =
          _editorKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        // Estimate position based on text offset
        // In production, you'd get exact position from RenderParagraph
        final lineHeight = 24.0; // Approximate line height
        final lines = text.substring(0, offset).split('\n').length - 1;
        final y = 72.0 + (lines * lineHeight); // 72 is padding

        ref.read(inlineButtonPositionProvider.notifier).state = Offset(
          20,
          y,
        ); // 20px from left edge
        ref.read(showInlineButtonsProvider.notifier).state = true;
      }
    } else {
      ref.read(showInlineButtonsProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main editor
        Container(
          key: _editorKey,
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
                    padding: const EdgeInsets.all(72),
                    placeholder: 'Start typing or press + to insert...',
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
        ),
        // Inline buttons
        const InlineActionButtons(),
        // Chat panel overlay
        Consumer(
          builder: (context, ref, child) {
            final showChat = ref.watch(chatPanelProvider);
            if (!showChat) return const SizedBox.shrink();
            return const ChatPanel();
          },
        ),
      ],
    );
  }
}
