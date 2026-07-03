import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';
import 'ai_assistant/ai_assistant_command_surface.dart';
import 'ai_assistant_widgets.dart';

/// Connects document state to the reusable AI writing assistant surface.
class AIAssistantPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool showHeader;

  const AIAssistantPanel({super.key, this.onClose, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentState = ref.watch(documentProvider);
    final aiService = ref.watch(aiAssistantServiceProvider);

    return AIAssistantCommandSurface(
      hasApiKey: aiService.hasApiKey,
      isProcessing: documentState.isAIProcessing,
      result: documentState.aiResult,
      contextLabel: _contextLabel(documentState.controller),
      actionLabelBuilder: aiService.getActionLabel,
      actionIconBuilder: aiService.getActionIcon,
      onConfigure: () => AIApiKeyDialog.show(context),
      onActionSelected: (action) =>
          ref.read(documentProvider.notifier).applyAIAction(action),
      onCopyResult: () => _copyResult(context, documentState.aiResult),
      onInsertResult: () {
        ref.read(documentProvider.notifier).insertAIResult();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('AI text inserted')));
      },
      onReplaceResult: () {
        ref.read(documentProvider.notifier).replaceWithAIResult();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text replaced with AI suggestion')),
        );
      },
      onClearResult: () {
        ref.read(documentProvider.notifier).clearAIResult();
      },
      onClose: onClose,
      showHeader: showHeader,
    );
  }

  String _contextLabel(quill.QuillController controller) {
    final selection = controller.selection;
    final baseOffset = selection.baseOffset;
    final extentOffset = selection.extentOffset;
    final selectedLength = (baseOffset - extentOffset).abs();
    if (selectedLength > 0) {
      return '$selectedLength selected chars';
    }

    final text = controller.document.toPlainText().trim();
    if (text.isEmpty) return 'No text selected';
    return 'Full document';
  }

  void _copyResult(BuildContext context, String? result) {
    if (result == null) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}
