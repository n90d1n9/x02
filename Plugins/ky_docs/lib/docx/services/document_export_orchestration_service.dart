import '../models/document_state.dart';
import '../models/export_options.dart';
import 'document_async_operation_service.dart';
import 'document_export_service.dart';

typedef ExportStateReader = DocumentState Function();
typedef ExportStateEmitter = void Function(DocumentState state);

class DocumentExportOrchestrationService {
  final DocumentExportService exportService;
  final DocumentAsyncOperationService asyncOperationService;

  const DocumentExportOrchestrationService({
    required this.exportService,
    this.asyncOperationService = const DocumentAsyncOperationService(),
  });

  Future<String> exportDocx({
    required ExportStateReader readState,
    required ExportStateEmitter emitState,
  }) async {
    final path = await asyncOperationService.run<String>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to export DOCX',
      rethrowOnError: true,
      operation: () async {
        final current = readState();
        final path = await exportService.exportDocx(
          text: current.controller.document.toPlainText(),
          metadata: current.metadata,
          document: current.controller.document,
        );

        emitState(
          readState().copyWith(isLoading: false, hasUnsavedChanges: false),
        );
        return path;
      },
    );

    return path!;
  }

  Future<String> exportPdf({
    required ExportStateReader readState,
    required ExportStateEmitter emitState,
    ExportOptions options = const ExportOptions(),
  }) async {
    final path = await asyncOperationService.run<String>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to export PDF',
      rethrowOnError: true,
      operation: () async {
        final current = readState();
        final path = await exportService.exportPdf(
          text: current.controller.document.toPlainText(),
          metadata: current.metadata,
          document: current.controller.document,
          options: options,
        );

        emitState(readState().copyWith(isLoading: false));
        return path;
      },
    );

    return path!;
  }

  Future<List<String>> exportMultiple({
    required ExportStateReader readState,
    required ExportStateEmitter emitState,
  }) async {
    final paths = await asyncOperationService.run<List<String>>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to export',
      fallback: const [],
      operation: () async {
        final current = readState();
        final result = await exportService.exportMultiple(
          text: current.controller.document.toPlainText(),
          metadata: current.metadata,
          document: current.controller.document,
        );

        emitState(
          readState().copyWith(
            isLoading: false,
            errorMessage: result.errorMessage,
            hasUnsavedChanges: result.exported(DocumentExportFormat.docx)
                ? false
                : readState().hasUnsavedChanges,
          ),
        );
        return result.paths;
      },
    );

    return paths ?? [];
  }
}
