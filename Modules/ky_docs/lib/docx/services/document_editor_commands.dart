import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_import_status.dart';
import '../states/provider.dart';
import '../widgets/document_import_preview_dialog.dart';
import '../widgets/pdf_export_options_dialog.dart';
import 'document_print_service.dart';

class DocumentEditorCommands {
  final WidgetRef ref;
  final DocumentPrintService printService;

  const DocumentEditorCommands(
    this.ref, {
    this.printService = const DocumentPrintService(),
  });

  Future<void> saveFromShortcut(BuildContext context) async {
    await ref.read(documentProvider.notifier).saveDocument();
    if (!context.mounted) return;

    _showSnackBar(
      context,
      const SnackBar(
        content: Text('Document saved (Ctrl+S)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> save(BuildContext context) async {
    await ref.read(documentProvider.notifier).saveDocument();
    if (!context.mounted) return;

    _showSnackBar(
      context,
      const SnackBar(
        content: Text('Document saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> print(BuildContext context) async {
    try {
      final text = ref.read(documentProvider).controller.document.toPlainText();
      await printService.printPlainText(text);
    } catch (error) {
      if (!context.mounted) return;

      _showErrorSnackBar(context, 'Print error: $error');
    }
  }

  Future<void> createNewDocument() async {
    await ref.read(documentProvider.notifier).createNewDocument();
  }

  Future<void> import(BuildContext context, String type) async {
    final notifier = ref.read(documentProvider.notifier);
    try {
      if (type == 'docx') {
        await notifier.importFromDocx(
          reviewImport: (preview) => _reviewImport(context, preview),
        );
      } else if (type == 'pdf') {
        await notifier.importFromPdf(
          reviewImport: (preview) => _reviewImport(context, preview),
        );
      }
      if (!context.mounted) return;

      _showImportResult(context);
    } catch (error) {
      if (!context.mounted) return;

      _showErrorSnackBar(context, 'Import failed: $error');
    }
  }

  Future<bool> _reviewImport(
    BuildContext context,
    DocumentImportPreview preview,
  ) {
    if (!context.mounted) return Future.value(false);
    return DocumentImportPreviewDialog.show(context, preview: preview);
  }

  void _showImportResult(BuildContext context) {
    final status = ref.read(documentProvider).importStatus;
    switch (status.phase) {
      case DocumentImportPhase.completed:
        _showSnackBar(
          context,
          SnackBar(
            content: Text(status.message),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case DocumentImportPhase.cancelled:
        _showSnackBar(
          context,
          SnackBar(
            content: Text(status.message),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      case DocumentImportPhase.failed:
        _showErrorSnackBar(context, status.details);
        break;
      case DocumentImportPhase.idle:
      case DocumentImportPhase.picking:
      case DocumentImportPhase.importing:
      case DocumentImportPhase.previewing:
        break;
    }
  }

  Future<void> export(BuildContext context, String type) async {
    try {
      if (type == 'pdf_advanced') {
        await _exportAdvancedPdf(context);
        return;
      }

      final path = await _exportPath(type);
      if (!context.mounted) return;

      _showShareSnackBar(
        context,
        message: 'Exported successfully',
        path: path,
        duration: const Duration(seconds: 3),
      );
    } catch (error) {
      if (!context.mounted) return;

      _showErrorSnackBar(context, 'Export failed: $error');
    }
  }

  Future<String> _exportPath(String type) {
    final notifier = ref.read(documentProvider.notifier);
    if (type == 'docx') {
      return notifier.exportToDocx();
    }
    return notifier.exportToPdf();
  }

  Future<void> _exportAdvancedPdf(BuildContext context) async {
    final options = await PdfExportOptionsDialog.show(context);
    if (options == null) return;

    final path = await ref
        .read(documentProvider.notifier)
        .exportToPdf(options: options);
    if (!context.mounted) return;

    _showShareSnackBar(
      context,
      message: 'PDF exported with custom options',
      path: path,
    );
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    _showSnackBar(
      context,
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showShareSnackBar(
    BuildContext context, {
    required String message,
    required String path,
    Duration? duration,
  }) {
    _showSnackBar(
      context,
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            unawaited(
              SharePlus.instance.share(ShareParams(files: [XFile(path)])),
            );
          },
        ),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
