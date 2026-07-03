import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';
import 'document_pagination_service.dart';

class DocumentEditorLifecycle {
  static const defaultAutoSaveInterval = Duration(minutes: 2);

  final WidgetRef ref;
  final Duration autoSaveInterval;
  final DocumentPaginationService paginationService;

  Timer? _autoSaveTimer;
  bool _isAutoSaving = false;

  DocumentEditorLifecycle(
    this.ref, {
    this.autoSaveInterval = defaultAutoSaveInterval,
    this.paginationService = const DocumentPaginationService(),
  });

  void start(BuildContext context) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (_) {
      unawaited(autoSave(context));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      refreshPagination();
    });
  }

  Future<void> autoSave(BuildContext context) async {
    if (_isAutoSaving) return;

    final documentState = ref.read(documentProvider);
    if (!documentState.hasUnsavedChanges || documentState.isLoading) return;

    _isAutoSaving = true;
    try {
      await ref.read(documentProvider.notifier).saveDocument();
      if (!context.mounted) return;

      final saveError = ref.read(documentProvider).errorMessage;
      if (saveError != null) {
        _showSnackBar(
          context,
          SnackBar(
            content: Text('Auto-save failed: $saveError'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _showSnackBar(
        context,
        const SnackBar(
          content: Text('Auto-saved'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      _showSnackBar(
        context,
        SnackBar(
          content: Text('Auto-save failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isAutoSaving = false;
    }
  }

  void refreshPagination() {
    final documentState = ref.read(documentProvider);
    final pages = paginationService.estimateTotalPages(
      text: documentState.controller.document.toPlainText(),
      pageSettings: documentState.pageSettings,
    );

    ref.read(documentProvider.notifier).updatePageCount(pages);
  }

  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
