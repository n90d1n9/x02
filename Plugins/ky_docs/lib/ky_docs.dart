// Public API barrel for ky_docs.
//
// Consumers import this file; internal code should import files directly.
// Keep this list sorted alphabetically by path within each section.

// ── Engine (Rust FFI integration) ────────────────────────────────────────────

export 'engine/engine.dart'
    show DocumentEngine, Document, DocumentBlock, TextSpan, TextStyle, DocxParserService, DocxMetadata, DocxContent, NativeDocumentHandle;

// ── Native Engine Widgets (MS Word/GDocs-like editor) ───────────────────────

export 'docx/widgets/native_document_canvas.dart'
    show NativeDocumentCanvas, NativeDocumentState, NativeDocumentNotifier,
         documentEngineProvider, docxParserProvider, nativeDocumentProvider,
         DocxImportDialog;

// ── Screens ─────────────────────────────────────────────────────────────────

export 'docx/screens/document_editor_page.dart' show DocumentEditorPage;
export 'docx/screens/document_editor_screen.dart' show DocumentEditorScreen;
export 'docx/screens/document_list_page.dart' show DocumentListPage;

// ── Suite (app shell, theme, workspace, surface routing) ────────────────────

export 'docx/suite/ky_docs_app.dart' show KyDocsApp;
export 'docx/suite/ky_docs_surface.dart'
    show KyDocsSurface, KyDocsSurfaceCatalog, KyDocsSurfaceMeta;
export 'docx/suite/ky_docs_theme.dart' show KyDocsTheme;
export 'docx/suite/ky_docs_workspace.dart' show KyDocsWorkspace;

// ── Product descriptor ───────────────────────────────────────────────────────

export 'office_product.dart';
