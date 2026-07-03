import 'dart:io';

import '../models/document_import_status.dart';
import 'document_import_extractor.dart';
import 'waraq_document_bridge.dart';
import 'waraq_pdf_extraction_mapper.dart';

typedef WaraqPdfImportWorkspaceProvider =
    Future<WaraqPdfImportWorkspace> Function();

class WaraqPdfImportWorkspace {
  final Directory directory;
  final bool deleteWhenDone;

  const WaraqPdfImportWorkspace({
    required this.directory,
    this.deleteWhenDone = true,
  });
}

class WaraqProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const WaraqProcessResult({
    required this.exitCode,
    required this.stdout,
    this.stderr = '',
  });
}

abstract class WaraqProcessRunner {
  Future<WaraqProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
  });
}

class DartWaraqProcessRunner implements WaraqProcessRunner {
  const DartWaraqProcessRunner();

  @override
  Future<WaraqProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    return WaraqProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}

class WaraqPdfCliCommand {
  final String executable;
  final List<String> argumentsBeforePath;
  final String outputFormat;

  const WaraqPdfCliCommand({
    this.executable = 'cargo',
    this.argumentsBeforePath = const [
      'run',
      '--quiet',
      '--example',
      'cli',
      '--',
    ],
    this.outputFormat = 'json',
  });

  List<String> argumentsFor(String filePath) {
    return [...argumentsBeforePath, filePath, outputFormat];
  }
}

class WaraqPdfImportException implements Exception {
  final int exitCode;
  final String stderr;

  const WaraqPdfImportException({required this.exitCode, required this.stderr});

  @override
  String toString() {
    final details = stderr.trim();
    return details.isEmpty
        ? 'Waraq PDF import failed with exit code $exitCode'
        : 'Waraq PDF import failed with exit code $exitCode: $details';
  }
}

enum WaraqPdfFailurePolicy { fail, fallbackToExtractor }

class WaraqPdfImportConfiguration {
  final WaraqProcessRunner runner;
  final WaraqPdfCliCommand command;
  final WaraqPdfExtractionMapper mapper;
  final WaraqPdfImportWorkspaceProvider workspaceProvider;
  final WaraqPdfFailurePolicy failurePolicy;

  const WaraqPdfImportConfiguration({
    this.runner = const DartWaraqProcessRunner(),
    this.command = const WaraqPdfCliCommand(),
    this.mapper = const WaraqPdfExtractionMapper(),
    this.workspaceProvider = createWaraqPdfImportWorkspace,
    this.failurePolicy = WaraqPdfFailurePolicy.fail,
  });

  const WaraqPdfImportConfiguration.resilient({
    this.runner = const DartWaraqProcessRunner(),
    this.command = const WaraqPdfCliCommand(),
    this.mapper = const WaraqPdfExtractionMapper(),
    this.workspaceProvider = createWaraqPdfImportWorkspace,
  }) : failurePolicy = WaraqPdfFailurePolicy.fallbackToExtractor;

  WaraqPdfImportExtractor createExtractor({
    DocumentImportExtractor? fallbackExtractor,
  }) {
    return WaraqPdfImportExtractor(
      runner: runner,
      command: command,
      mapper: mapper,
      workspaceProvider: workspaceProvider,
      fallbackExtractor: fallbackExtractor,
      failurePolicy: failurePolicy,
    );
  }
}

class WaraqPdfImportExtractor implements DocumentStructuredImportExtractor {
  final WaraqProcessRunner runner;
  final WaraqPdfCliCommand command;
  final WaraqPdfExtractionMapper mapper;
  final WaraqPdfImportWorkspaceProvider workspaceProvider;
  final DocumentImportExtractor? fallbackExtractor;
  final WaraqPdfFailurePolicy failurePolicy;

  const WaraqPdfImportExtractor({
    this.runner = const DartWaraqProcessRunner(),
    this.command = const WaraqPdfCliCommand(),
    this.mapper = const WaraqPdfExtractionMapper(),
    this.workspaceProvider = createWaraqPdfImportWorkspace,
    this.fallbackExtractor,
    this.failurePolicy = WaraqPdfFailurePolicy.fail,
  });

  @override
  Future<DocumentImportContent> extractContent(
    WaraqImportRequest request,
  ) async {
    if (request.format != WaraqDocumentFormat.pdf) {
      return _extractFallbackContent(request);
    }

    if (failurePolicy == WaraqPdfFailurePolicy.fallbackToExtractor) {
      try {
        return await _extractNativePdfContent(request);
      } catch (error) {
        return _extractFallbackContent(
          request,
          method: DocumentImportMethod.fallbackExtractor,
          warningMessage:
              'Native Waraq PDF import failed; used Dart fallback: $error',
        );
      }
    }

    return _extractNativePdfContent(request);
  }

  Future<DocumentImportContent> _extractNativePdfContent(
    WaraqImportRequest request,
  ) async {
    final workspace = await workspaceProvider();
    final inputFile = File(
      _filePath(workspace.directory, _safeInputFileName(request.fileName)),
    );

    try {
      await inputFile.writeAsBytes(request.bytes, flush: true);

      final result = await runner.run(
        executable: command.executable,
        arguments: command.argumentsFor(inputFile.path),
        workingDirectory: request.libraryPaths.pdfCore,
      );

      if (result.exitCode != 0) {
        throw WaraqPdfImportException(
          exitCode: result.exitCode,
          stderr: result.stderr,
        );
      }

      return mapper.fromPdfCoreJson(
        result.stdout,
        fallbackTitle: _titleFromFileName(request.fileName),
      );
    } finally {
      await _cleanup(workspace: workspace, inputFile: inputFile);
    }
  }

  @override
  Future<String> extractText(WaraqImportRequest request) async {
    return (await extractContent(request)).text;
  }

  Future<DocumentImportContent> _extractFallbackContent(
    WaraqImportRequest request, {
    DocumentImportMethod method = DocumentImportMethod.dartExtractor,
    String? warningMessage,
  }) async {
    final fallback = fallbackExtractor;
    if (fallback == null) {
      throw UnsupportedError('Waraq native import only supports PDF files');
    }

    DocumentImportContent content;
    if (fallback is DocumentStructuredImportExtractor) {
      content = await fallback.extractContent(request);
    } else {
      content = DocumentImportContent.plainText(
        await fallback.extractText(request),
      );
    }

    return content.copyWith(method: method, warningMessage: warningMessage);
  }

  Future<void> _cleanup({
    required WaraqPdfImportWorkspace workspace,
    required File inputFile,
  }) async {
    if (workspace.deleteWhenDone) {
      if (await workspace.directory.exists()) {
        await workspace.directory.delete(recursive: true);
      }
      return;
    }

    if (await inputFile.exists()) {
      await inputFile.delete();
    }
  }

  String _safeInputFileName(String fileName) {
    final safeName = fileName
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .trim();
    final baseName = safeName.isEmpty || safeName == '.' || safeName == '..'
        ? 'input.pdf'
        : safeName;

    return baseName.toLowerCase().endsWith('.pdf') ? baseName : '$baseName.pdf';
  }

  String _titleFromFileName(String fileName) {
    final safeName = _safeInputFileName(fileName);
    final title = safeName.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
    return title.isEmpty ? 'Untitled Document' : title;
  }

  String _filePath(Directory directory, String fileName) {
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }
}

Future<WaraqPdfImportWorkspace> createWaraqPdfImportWorkspace() async {
  return WaraqPdfImportWorkspace(
    directory: await Directory.systemTemp.createTemp('ky_docs_waraq_pdf_'),
  );
}
