import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/document_outline.dart';
import '../../models/document_state.dart';
import '../../services/document_outline_service.dart';
import '../outline/outline_panel.dart';
import '../page_navigation/document_page_navigation_model.dart';
import '../page_navigation/document_page_navigator_panel.dart';

/// Builds navigation summaries and fallback panels for More Options commands.
class DocumentMoreOptionsNavigationLauncher {
  static const _outlineService = DocumentOutlineService();

  const DocumentMoreOptionsNavigationLauncher();

  List<DocumentOutline> generateOutline(DocumentState docState) {
    var nextId = 0;
    return _outlineService.generateOutline(
      text: docState.controller.document.toPlainText(),
      createId: () => 'more-options-outline-${++nextId}',
    );
  }

  String outlineSubtitle(int outlineCount) {
    if (outlineCount == 0) return 'No headings found';

    final label = outlineCount == 1 ? 'heading' : 'headings';
    return '$outlineCount $label';
  }

  String pageNavigatorSubtitle(DocumentState docState) {
    final totalPages = docState.totalPages.clamp(1, 9999).toInt();
    final currentPage = docState.currentPage.clamp(1, totalPages).toInt();
    final label = totalPages == 1 ? 'page' : 'pages';
    return 'Page $currentPage of $totalPages $label';
  }

  Future<void> showOutline(
    BuildContext context, {
    required DocumentState docState,
    required VoidCallback? onShowOutline,
  }) async {
    if (onShowOutline != null) {
      onShowOutline();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: DocxOutlinePanel(
              outline: generateOutline(docState),
              onJumpToOffset: (offset) {
                _jumpToOffset(docState, offset);
                Navigator.pop(sheetContext);
              },
              onClose: () => Navigator.pop(sheetContext),
            ),
          ),
        );
      },
    );
  }

  Future<void> showPageNavigator(
    BuildContext context, {
    required DocumentState docState,
    required ValueChanged<int> onSelectPage,
    required VoidCallback? onShowPageNavigator,
  }) async {
    if (onShowPageNavigator != null) {
      onShowPageNavigator();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: DocumentPageNavigatorPanel(
              model: DocumentPageNavigationModel(
                currentPage: docState.currentPage,
                totalPages: docState.totalPages,
                pageSettings: docState.pageSettings,
              ),
              onPageSelected: (pageNumber) {
                onSelectPage(pageNumber);
                _jumpToPage(docState, pageNumber);
                Navigator.pop(sheetContext);
              },
              onClose: () => Navigator.pop(sheetContext),
            ),
          ),
        );
      },
    );
  }

  void _jumpToOffset(DocumentState docState, int offset) {
    final textLength = docState.controller.document.toPlainText().length;
    docState.controller.updateSelection(
      TextSelection.collapsed(offset: offset.clamp(0, textLength).toInt()),
      quill.ChangeSource.local,
    );
  }

  void _jumpToPage(DocumentState docState, int pageNumber) {
    final totalPages = docState.totalPages.clamp(1, 9999).toInt();
    final normalizedPage = pageNumber.clamp(1, totalPages).toInt();
    final textLength = docState.controller.document.toPlainText().length;
    final offset = totalPages == 1
        ? 0
        : (((normalizedPage - 1) / totalPages) * textLength).round();
    _jumpToOffset(docState, offset);
  }
}
