import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/presentation_file_format.dart';
import '../../services/presentation_io/pptx_export_service.dart';
import '../../services/presentation_io/pptx_import_service.dart';
import '../../services/presentation_io/presentation_file_capability_service.dart';
import '../../states/component_provider.dart';
import '../../states/history_provider.dart';
import '../../states/presentation_provider.dart';
import 'presentation_file_sections.dart';
import 'sidebar_section.dart';

typedef PptxFilePicker = Future<PickedPptxFile?> Function();
typedef PptxFileSaver =
    Future<String?> Function(String fileName, Uint8List bytes);

/// File picked from disk for native PPTX import.
class PickedPptxFile {
  final String name;
  final Uint8List bytes;

  const PickedPptxFile({required this.name, required this.bytes});
}

/// Sidebar panel for importing, exporting, and reviewing deck file support.
class PresentationFilePanel extends ConsumerWidget {
  final PresentationFileCapabilityService capabilityService;
  final PptxImportService importService;
  final PptxExportService exportService;
  final PptxFilePicker? pickPptxFile;
  final PptxFileSaver? savePptxFile;

  const PresentationFilePanel({
    super.key,
    this.capabilityService = const PresentationFileCapabilityService(),
    this.importService = const PptxImportService(),
    this.exportService = const PptxExportService(),
    this.pickPptxFile,
    this.savePptxFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final theme = presentation.theme;

    return SidebarSection(
      title: 'PowerPoint Files',
      subtitle: 'Import and export decks from the editor workspace.',
      icon: Icons.folder_open_outlined,
      gradientColors: [theme.primaryColor, theme.secondaryColor],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PresentationFileSummaryCard(
            slideCount: presentation.slides.length,
            title: presentation.title,
            slideSize: presentation.slideSize,
            accentColor: theme.primaryColor,
          ),
          const SizedBox(height: 12),
          PresentationFileCapabilityGroup(
            title: 'Import',
            icon: Icons.file_upload_outlined,
            color: theme.primaryColor,
            accentColor: theme.primaryColor,
            capabilities: capabilityService.forOperation(
              PresentationFileOperation.import,
            ),
            onSelected: (capability) =>
                _handleCapability(context, ref, capability),
          ),
          const SizedBox(height: 4),
          PresentationFileCapabilityGroup(
            title: 'Export',
            icon: Icons.file_download_outlined,
            color: theme.secondaryColor,
            accentColor: theme.secondaryColor,
            capabilities: capabilityService.forOperation(
              PresentationFileOperation.export,
            ),
            onSelected: (capability) =>
                _handleCapability(context, ref, capability),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCapability(
    BuildContext context,
    WidgetRef ref,
    PresentationFileCapability capability,
  ) async {
    if (!capability.isNative) {
      _showMessage(context, _nonNativeMessage(capability));
      return;
    }

    switch (capability.operation) {
      case PresentationFileOperation.import:
        await _importPptx(context, ref);
      case PresentationFileOperation.export:
        await _exportPptx(context, ref);
    }
  }

  Future<void> _importPptx(BuildContext context, WidgetRef ref) async {
    try {
      final pickedFile = await (pickPptxFile ?? _defaultPickPptxFile)();
      if (!context.mounted) return;
      if (pickedFile == null) {
        _showMessage(context, 'Import cancelled.');
        return;
      }

      final before = ref.read(presentationProvider);
      final imported = importService.importBytes(
        pickedFile.bytes,
        title: _titleFromFileName(pickedFile.name),
      );

      ref.read(presentationProvider.notifier).loadPresentation(imported);
      ref.read(selectedComponentProvider.notifier).state = null;
      ref
          .read(historyProvider.notifier)
          .recordChange(before: before, after: imported, label: 'Import PPTX');

      _showMessage(
        context,
        'Imported ${imported.slides.length} slide${imported.slides.length == 1 ? '' : 's'} from ${pickedFile.name}.',
      );
    } on PptxImportException catch (error) {
      _showMessage(context, 'Import failed: ${error.message}');
    } catch (error) {
      _showMessage(context, 'Import failed: $error');
    }
  }

  Future<void> _exportPptx(BuildContext context, WidgetRef ref) async {
    try {
      final presentation = ref.read(presentationProvider);
      final fileName = '${_safeFileName(presentation.title)}.pptx';
      final bytes = Uint8List.fromList(exportService.exportBytes(presentation));
      final path = await (savePptxFile ?? _defaultSavePptxFile)(
        fileName,
        bytes,
      );
      if (!context.mounted) return;

      _showMessage(
        context,
        path == null ? 'Export cancelled.' : 'Exported $fileName.',
      );
    } catch (error) {
      _showMessage(context, 'Export failed: $error');
    }
  }

  Future<PickedPptxFile?> _defaultPickPptxFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return null;

    return PickedPptxFile(name: file.name, bytes: bytes);
  }

  Future<String?> _defaultSavePptxFile(String fileName, Uint8List bytes) {
    return FilePicker.saveFile(
      dialogTitle: 'Export PowerPoint deck',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pptx'],
      bytes: bytes,
    );
  }

  String _nonNativeMessage(PresentationFileCapability capability) {
    switch (capability.support) {
      case PresentationFileSupport.native:
        return capability.description;
      case PresentationFileSupport.converterRequired:
        return '${capability.format.label} needs a converter bridge before this action can run.';
      case PresentationFileSupport.planned:
        return '${capability.title} is planned for the next file pipeline phase.';
    }
  }

  String _titleFromFileName(String fileName) {
    return fileName.replaceFirst(RegExp(r'\.pptx$', caseSensitive: false), '');
  }

  String _safeFileName(String value) {
    final trimmed = value.trim().isEmpty ? 'presentation' : value.trim();
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
