import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../models/aiaction.dart';
import '../models/chart_type.dart';
import '../models/document_outline.dart';
import '../models/document_template.dart';
import '../models/document_theme.dart';
import '../models/export_options.dart';
import '../models/page_layout.dart';
import '../models/page_settings.dart';
import '../models/spell_check_error.dart';
import '../models/spell_check_service.dart';
import '../models/aiassistant_service.dart';
import '../models/cloud_sync_service.dart';
import '../models/collaboration_service.dart';
import '../models/document_state.dart';
import '../models/document_storage_service.dart';
import '../services/document_ai_orchestration_service.dart';
import '../services/document_change_service.dart';
import '../services/document_collaboration_orchestration_service.dart';
import '../services/document_comment_service.dart';
import '../services/document_creation_service.dart';
import '../services/document_embedded_content_service.dart';
import '../services/document_export_orchestration_service.dart';
import '../services/document_export_service.dart';
import '../services/document_import_service.dart';
import '../services/document_lifecycle_orchestration_service.dart';
import '../services/document_persistence_service.dart';
import '../services/document_properties_service.dart';
import '../services/document_spell_check_orchestration_service.dart';
import '../services/document_state_mutation_service.dart';
import '../services/document_structure_service.dart';
import '../services/document_track_changes_service.dart';
import '../services/docx_service.dart';
import '../services/pdf_service.dart';
import 'auto_save_service.dart';

/// Owns mutable document editor state and delegates operations to focused services.
class DocumentNotifier extends StateNotifier<DocumentState> {
  static const _changeService = DocumentChangeService();
  static const _commentService = CommentService();
  static const _trackChangesService = DocumentTrackChangesService();
  static const _structureService = DocumentStructureService();
  static const _embeddedContentService = DocumentEmbeddedContentService();
  static const _propertiesService = DocumentPropertiesService();
  static const _stateMutationService = DocumentStateMutationService();

  final DocumentExportOrchestrationService _exportOrchestrationService;
  final DocumentLifecycleOrchestrationService _lifecycleService;
  final DocumentAiOrchestrationService _aiOrchestrationService;
  final DocumentCollaborationOrchestrationService _collaborationService;
  final DocumentSpellCheckOrchestrationService _spellCheckOrchestrationService;
  final AutoSaveService _autoSaveService = AutoSaveService();
  final Uuid _uuid = const Uuid();

  DocumentNotifier(
    DocumentStorageService storage,
    DocxService docxService,
    PdfService pdfService,
    AIAssistantService aiService,
    CloudSyncService cloudSync,
    CollaborationService collaboration,
    SpellCheckService spellCheck, {
    DocumentImportService? documentImportService,
  }) : _exportOrchestrationService = DocumentExportOrchestrationService(
         exportService: DocumentExportService(
           docxService: docxService,
           pdfService: pdfService,
         ),
       ),
       _lifecycleService = DocumentLifecycleOrchestrationService(
         creationService: DocumentCreationService(
           createId: () => const Uuid().v4(),
         ),
         persistenceService: DocumentPersistenceService(
           storage: storage,
           cloudSync: cloudSync,
           createId: () => const Uuid().v4(),
         ),
         importService:
             documentImportService ??
             DocumentImportService(
               docxService: docxService,
               pdfService: pdfService,
             ),
       ),
       _collaborationService =
           DocumentCollaborationOrchestrationService.fromCollaboration(
             collaboration,
           ),
       _aiOrchestrationService = DocumentAiOrchestrationService.fromProcessor(
         aiService.processText,
       ),
       _spellCheckOrchestrationService =
           DocumentSpellCheckOrchestrationService.fromSpellCheck(spellCheck),
       super(
         DocumentLifecycleOrchestrationService.initialState(
           createId: () => const Uuid().v4(),
         ),
       ) {
    state.controller.addListener(_onDocumentChanged);
    _initializeStorage();
    _initializeAutoSave();
  }

  Future<void> _initializeStorage() async {
    await _lifecycleService.initializeStorage(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  void _initializeAutoSave() {
    _autoSaveService.initialize(this);
  }

  void _onDocumentChanged() {
    final change = _changeService.applyDocumentChange(
      text: state.controller.document.toPlainText(),
      metadata: state.metadata,
      pageSettings: state.pageSettings,
    );

    _markChanged(
      (current) => current.copyWith(
        metadata: change.metadata,
        totalPages: change.totalPages,
      ),
    );
    
    // Trigger auto-save debounce timer
    _autoSaveService.onDocumentChanged();
  }

  Future<void> createNewDocument() async {
    await _lifecycleService.createNew(
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
    );
  }

  Future<void> createFromTemplate(DocumentTemplate template) async {
    await _lifecycleService.createFromTemplate(
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
      template: template,
    );
  }

  Future<void> saveDocument() async {
    await _lifecycleService.save(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  Future<bool> saveDocumentAs({
    required String newTitle,
    required String format,
    String? location,
  }) async {
    try {
      // Export to the specified format
      final exportedPath = await _exportOrchestrationService.exportToPath(
        readState: () => state,
        emitState: (nextState) => state = nextState,
        format: format,
        customFileName: newTitle,
        location: location,
      );

      if (exportedPath.isNotEmpty) {
        // Update document metadata with new title and path
        state = state.copyWith(
          metadata: _propertiesService.updateTitle(
            metadata: state.metadata,
            title: newTitle,
          ),
          hasUnsavedChanges: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save as: $e');
      return false;
    }
  }

  Future<void> loadDocument(String id) async {
    await _lifecycleService.load(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
      id: id,
    );
  }

  Future<void> importFromDocx({
    DocumentImportPreviewReviewer? reviewImport,
  }) async {
    await _lifecycleService.importDocx(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
      reviewImport: reviewImport,
    );
  }

  Future<void> importFromPdf({
    DocumentImportPreviewReviewer? reviewImport,
  }) async {
    await _lifecycleService.importPdf(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
      reviewImport: reviewImport,
    );
  }

  Future<String> exportToDocx() async {
    return _exportOrchestrationService.exportDocx(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  Future<String> exportToPdf({ExportOptions? options}) async {
    return _exportOrchestrationService.exportPdf(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      options: options ?? const ExportOptions(),
    );
  }

  void updateTitle(String title) {
    _markChanged(
      (current) => current.copyWith(
        metadata: _propertiesService.updateTitle(
          metadata: current.metadata,
          title: title,
        ),
      ),
    );
  }

  void toggleFavorite() {
    _markChanged(
      (current) => current.copyWith(
        metadata: _propertiesService.toggleFavorite(current.metadata),
      ),
    );
  }

  void moveToFolder(String? folderId) {
    _markChanged(
      (current) => current.copyWith(
        metadata: _propertiesService.moveToFolder(
          metadata: current.metadata,
          folderId: folderId,
        ),
      ),
    );
  }

  Future<void> insertImage() async {
    try {
      await _embeddedContentService.insertImage(controller: state.controller);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to insert image: $e');
    }
  }

  Future<List<String>> exportToMultipleFormats() async {
    return _exportOrchestrationService.exportMultiple(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  Future<void> applyAIAction(AIAction action) async {
    await _aiOrchestrationService.applyAction(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      action: action,
    );
  }

  void replaceWithAIResult() {
    _aiOrchestrationService.replaceResult(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  void insertAIResult() {
    _aiOrchestrationService.insertResult(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  void clearAIResult() {
    _aiOrchestrationService.clearResult(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  // Table operations
  void insertTable(int rows, int columns) {
    final insertion = _embeddedContentService.insertTable(
      controller: state.controller,
      currentTables: state.tables,
      id: _uuid.v4(),
      rows: rows,
      columns: columns,
    );

    _markChanged((current) => current.copyWith(tables: insertion.tables));
  }

  void updateTableCell(String tableId, int row, int col, String value) {
    final tables = _embeddedContentService.updateTableCell(
      currentTables: state.tables,
      tableId: tableId,
      row: row,
      column: col,
      value: value,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  void addTableRow(String tableId) {
    final tables = _embeddedContentService.addTableRow(
      currentTables: state.tables,
      tableId: tableId,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  void addTableColumn(String tableId) {
    final tables = _embeddedContentService.addTableColumn(
      currentTables: state.tables,
      tableId: tableId,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  void deleteTableRow(String tableId, int rowIndex) {
    final tables = _embeddedContentService.deleteTableRow(
      currentTables: state.tables,
      tableId: tableId,
      rowIndex: rowIndex,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  void deleteTableColumn(String tableId, int colIndex) {
    final tables = _embeddedContentService.deleteTableColumn(
      currentTables: state.tables,
      tableId: tableId,
      columnIndex: colIndex,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  void deleteTable(String tableId) {
    final tables = _embeddedContentService.deleteTable(
      currentTables: state.tables,
      tableId: tableId,
    );

    _markChanged((current) => current.copyWith(tables: tables));
  }

  // Chart operations
  void insertChart(
    ChartType type,
    String title,
    List<String> labels,
    List<double> values,
  ) {
    final insertion = _embeddedContentService.insertChart(
      controller: state.controller,
      currentCharts: state.charts,
      id: _uuid.v4(),
      type: type,
      title: title,
      labels: labels,
      values: values,
    );

    _markChanged((current) => current.copyWith(charts: insertion.charts));
  }

  void updateChart(
    String chartId,
    String title,
    List<String> labels,
    List<double> values,
  ) {
    final charts = _embeddedContentService.updateChart(
      currentCharts: state.charts,
      chartId: chartId,
      title: title,
      labels: labels,
      values: values,
    );

    _markChanged((current) => current.copyWith(charts: charts));
  }

  void deleteChart(String chartId) {
    final charts = _embeddedContentService.deleteChart(
      currentCharts: state.charts,
      chartId: chartId,
    );

    _markChanged((current) => current.copyWith(charts: charts));
  }

  // Drawing operations
  void insertDrawing(Uint8List imageBytes, double width, double height) {
    final insertion = _embeddedContentService.insertDrawing(
      controller: state.controller,
      currentDrawings: state.drawings,
      id: _uuid.v4(),
      imageBytes: imageBytes,
      width: width,
      height: height,
    );

    _markChanged((current) => current.copyWith(drawings: insertion.drawings));
  }

  void deleteDrawing(String drawingId) {
    final drawings = _embeddedContentService.deleteDrawing(
      currentDrawings: state.drawings,
      drawingId: drawingId,
    );

    _markChanged((current) => current.copyWith(drawings: drawings));
  }

  // Shape operations (simple geometric shapes as drawings)
  Future<void> insertShape(String shapeType) async {
    final insertion = await _embeddedContentService.insertShape(
      controller: state.controller,
      currentDrawings: state.drawings,
      createId: _uuid.v4,
      shapeType: shapeType,
    );
    if (insertion == null) return;

    _markChanged((current) => current.copyWith(drawings: insertion.drawings));
  }

  // Page layout operations
  void updatePageSettings(PageSettings settings) {
    _markChanged((current) => current.copyWith(pageSettings: settings));
    _calculatePagination();
  }

  void setPageLayout(PageLayout layout) {
    _markChanged((current) => current.copyWith(currentLayout: layout));
  }

  void updatePageCount(int totalPages) {
    final pageCount = _structureService.normalizePageCount(totalPages);
    state = state.copyWith(
      currentPage: _structureService.normalizePageNumber(
        state.currentPage,
        pageCount,
      ),
      totalPages: pageCount,
    );
  }

  void selectPage(int pageNumber) {
    state = state.copyWith(
      currentPage: _structureService.normalizePageNumber(
        pageNumber,
        state.totalPages,
      ),
    );
  }

  void _calculatePagination() {
    final totalPages = _structureService.estimateTotalPages(
      controller: state.controller,
      pageSettings: state.pageSettings,
    );
    state = state.copyWith(
      currentPage: _structureService.normalizePageNumber(
        state.currentPage,
        totalPages,
      ),
      totalPages: totalPages,
    );
  }

  // Footnote operations
  void addFootnote(String text) {
    final insertion = _structureService.addFootnote(
      controller: state.controller,
      currentFootnotes: state.footnotes,
      id: _uuid.v4(),
      text: text,
    );

    _markChanged((current) => current.copyWith(footnotes: insertion.footnotes));
  }

  void updateFootnote(String id, String text) {
    final footnotes = _structureService.updateFootnote(
      currentFootnotes: state.footnotes,
      id: id,
      text: text,
    );

    _markChanged((current) => current.copyWith(footnotes: footnotes));
  }

  void deleteFootnote(String id) {
    final footnotes = _structureService.deleteFootnote(
      currentFootnotes: state.footnotes,
      id: id,
    );

    _markChanged((current) => current.copyWith(footnotes: footnotes));
  }

  // Comment operations
  void addComment(String text) {
    final anchor = _currentCommentAnchor();
    final comments = _commentService.addComment(
      currentComments: state.comments,
      id: _uuid.v4(),
      author: 'You',
      text: text,
      offset: anchor.offset,
      anchorText: anchor.anchorText,
    );
    if (identical(comments, state.comments)) return;

    _markChanged((current) => current.copyWith(comments: comments));
  }

  void resolveComment(String id) {
    final comments = _commentService.resolveComment(
      currentComments: state.comments,
      id: id,
    );

    _markChanged((current) => current.copyWith(comments: comments));
  }

  void reopenComment(String id) {
    final comments = _commentService.reopenComment(
      currentComments: state.comments,
      id: id,
    );

    _markChanged((current) => current.copyWith(comments: comments));
  }

  void deleteComment(String id) {
    final comments = _commentService.deleteComment(
      currentComments: state.comments,
      id: id,
    );

    _markChanged((current) => current.copyWith(comments: comments));
  }

  // Track changes operations
  void proposeTrackedChange(String replacementText) {
    final anchor = _currentTextAnchor();
    final changes = _trackChangesService.proposeChange(
      currentChanges: state.trackedChanges,
      id: _uuid.v4(),
      userId: 'local-user',
      userName: 'You',
      offset: anchor.offset,
      originalText: anchor.anchorText ?? '',
      replacementText: replacementText,
    );
    if (identical(changes, state.trackedChanges)) return;

    _markChanged((current) => current.copyWith(trackedChanges: changes));
  }

  void acceptTrackedChange(String id) {
    final change = _trackChangesService.findPendingChange(
      currentChanges: state.trackedChanges,
      id: id,
    );
    if (change == null) return;

    final documentLength = state.controller.document.length;
    final offset = _normalizeOffset(change.offset, documentLength);
    final length = change.length.clamp(0, documentLength - offset).toInt();
    state.controller.replaceText(
      offset,
      length,
      change.replacementText,
      TextSelection.collapsed(offset: offset + change.replacementText.length),
    );

    final changes = _trackChangesService.acceptChange(
      currentChanges: state.trackedChanges,
      id: id,
    );
    _markChanged((current) => current.copyWith(trackedChanges: changes));
  }

  void rejectTrackedChange(String id) {
    final changes = _trackChangesService.rejectChange(
      currentChanges: state.trackedChanges,
      id: id,
    );
    if (identical(changes, state.trackedChanges)) return;

    _markChanged((current) => current.copyWith(trackedChanges: changes));
  }

  void deleteTrackedChange(String id) {
    final changes = _trackChangesService.deleteChange(
      currentChanges: state.trackedChanges,
      id: id,
    );
    if (identical(changes, state.trackedChanges)) return;

    _markChanged((current) => current.copyWith(trackedChanges: changes));
  }

  // Outline generation
  List<DocumentOutline> generateOutline() {
    return _structureService.generateOutline(
      controller: state.controller,
      createId: _uuid.v4,
    );
  }

  // Collaboration features
  void enableCollaboration(String userId, String userName) {
    _collaborationService.enable(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      userId: userId,
      userName: userName,
    );
  }

  void disableCollaboration() {
    _collaborationService.disable(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  void updateCollaboratorCursor(int position) {
    _collaborationService.updateCursor(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      position: position,
    );
  }

  void addMockCollaborator(String name) {
    _collaborationService.addMockCollaborator(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      name: name,
    );
  }

  void _markChanged(DocumentStateUpdate update) {
    state = _stateMutationService.markChanged(state, update);
  }

  ({int offset, String? anchorText}) _currentCommentAnchor() {
    return _currentTextAnchor();
  }

  ({int offset, String? anchorText}) _currentTextAnchor() {
    final documentText = state.controller.document.toPlainText();
    final textLength = documentText.length;
    final selection = state.controller.selection;
    final start = _normalizeOffset(selection.start, textLength);
    final end = _normalizeOffset(selection.end, textLength);
    if (start == end) return (offset: start, anchorText: null);

    final anchorText = documentText.substring(start, end);
    return (offset: start, anchorText: anchorText);
  }

  int _normalizeOffset(int offset, int textLength) {
    return offset.clamp(0, textLength).toInt();
  }

  // Styling features
  void applyTheme(DocumentTheme theme) {
    _markChanged(
      (current) =>
          current.copyWith(currentTheme: _propertiesService.selectTheme(theme)),
    );
  }

  // Spell check features
  void toggleSpellCheck() {
    _spellCheckOrchestrationService.toggle(
      readState: () => state,
      emitState: (nextState) => state = nextState,
    );
  }

  void addWordToDictionary(String word) {
    _spellCheckOrchestrationService.addToDictionary(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      word: word,
    );
  }

  void ignoreSpellingError(String word) {
    _spellCheckOrchestrationService.ignoreWord(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      word: word,
    );
  }

  void replaceWithSuggestion(SpellCheckError error, String suggestion) {
    _spellCheckOrchestrationService.replaceWithSuggestion(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      error: error,
      suggestion: suggestion,
    );
  }

  void addTag(String tag) {
    final metadata = _propertiesService.addTag(
      metadata: state.metadata,
      tag: tag,
    );
    if (identical(metadata, state.metadata)) return;

    _markChanged((current) => current.copyWith(metadata: metadata));
  }

  void removeTag(String tag) {
    _markChanged(
      (current) => current.copyWith(
        metadata: _propertiesService.removeTag(
          metadata: current.metadata,
          tag: tag,
        ),
      ),
    );
  }

  Future<void> deleteDocument(String id) async {
    await _lifecycleService.delete(id);
  }

  Future<void> duplicateDocument() async {
    await _lifecycleService.duplicate(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
    );
  }

  void restoreVersion(int index) {
    _lifecycleService.restoreVersion(
      readState: () => state,
      emitState: (nextState) => state = nextState,
      activateController: _activateController,
      index: index,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  quill.QuillController _activateController(quill.QuillController controller) {
    controller.addListener(_onDocumentChanged);
    state.controller.removeListener(_onDocumentChanged);
    return controller;
  }

  @override
  void dispose() {
    _collaborationService.dispose();
    _spellCheckOrchestrationService.dispose();
    _autoSaveService.dispose();
    state.controller.removeListener(_onDocumentChanged);
    state.controller.dispose();
    super.dispose();
  }
}
