import 'collaboration_user.dart';
import 'comment.dart';
import 'document_change.dart';
import 'document_theme.dart';
import 'document_stats.dart';
import 'spell_check_error.dart';
import 'page_layout.dart';
import 'page_settings.dart';
import 'footnote.dart';
import 'document_table.dart';
import 'chart_data.dart';
import 'drawing_data.dart';
import 'document_import_status.dart';
import 'document_metadata.dart';
import 'document_version.dart';
import 'revision.dart';

class DocumentState {
  final String title;
  final DateTime lastModified;
  final bool isSaved;
  final DocumentStats stats;
  final List<Comment> comments;
  final String documentId;

  final String currentUserId;

  final DocumentMetadata metadata;
  final bool hasUnsavedChanges;
  final bool isLoading;
  final String? errorMessage;
  final List<DocumentVersion> versions;
  final int currentVersionIndex;
  final bool isAIProcessing;
  final String? aiResult;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final List<DocumentTable> tables;
  final List<ChartData> charts;
  final List<DrawingData> drawings;
  final PageSettings pageSettings;
  final PageLayout currentLayout;
  final List<Footnote> footnotes;

  final List<DocumentChange> trackedChanges;
  final RevisionManager revisionManager;
  final bool isTrackChangesEnabled;
  final int currentPage;
  final int totalPages;
  final List<CollaborationUser> collaborators;
  final bool isCollaborationEnabled;
  final DocumentTheme? currentTheme;
  final List<SpellCheckError> spellErrors;
  final bool spellCheckEnabled;
  final DocumentImportStatus importStatus;
  DocumentState({
    required this.metadata,
    this.hasUnsavedChanges = false,
    this.isLoading = false,
    this.errorMessage,
    this.versions = const [],
    this.currentVersionIndex = -1,
    this.isAIProcessing = false,
    this.aiResult,
    this.isSyncing = false,
    this.lastSyncTime,
    this.tables = const [],
    this.charts = const [],
    this.drawings = const [],
    this.pageSettings = const PageSettings(),
    this.currentLayout = PageLayout.print,
    this.footnotes = const [],
    this.comments = const [],
    this.trackedChanges = const [],
    RevisionManager? revisionManager,
    this.isTrackChangesEnabled = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.collaborators = const [],
    this.isCollaborationEnabled = false,
    DocumentTheme? currentTheme,
    this.spellErrors = const [],
    this.spellCheckEnabled = false,
    this.importStatus = const DocumentImportStatus.idle(),
    required this.title,
    required this.lastModified,
    required this.isSaved,
    DocumentStats? stats,
    required this.documentId,
    required this.currentUserId,
  }) : currentTheme = currentTheme ?? DocumentTheme.predefinedThemes[0],
       revisionManager = revisionManager ?? RevisionManager(),
       stats =
           stats ??
           DocumentStats(
             words: 0,
             characters: 0,
             charactersNoSpaces: 0,
             paragraphs: 0,
             readingTime: 0,
           );

  DocumentState copyWith({
    DocumentMetadata? metadata,
    bool? hasUnsavedChanges,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<DocumentVersion>? versions,
    int? currentVersionIndex,
    bool? isAIProcessing,
    String? aiResult,
    bool clearAIResult = false,
    bool? isSyncing,
    DateTime? lastSyncTime,
    List<DocumentTable>? tables,
    List<ChartData>? charts,
    List<DrawingData>? drawings,
    PageSettings? pageSettings,
    PageLayout? currentLayout,
    List<Footnote>? footnotes,
    List<Comment>? comments,
    List<DocumentChange>? trackedChanges,
    RevisionManager? revisionManager,
    bool? isTrackChangesEnabled,
    int? currentPage,
    int? totalPages,
    List<CollaborationUser>? collaborators,
    bool? isCollaborationEnabled,
    DocumentTheme? currentTheme,
    List<SpellCheckError>? spellErrors,
    bool? spellCheckEnabled,
    DocumentImportStatus? importStatus,
    bool clearImportStatus = false,
    String? title,
    DateTime? lastModified,
    bool? isSaved,
    DocumentStats? stats,
    String? documentId,
    String? currentUserId,
  }) {
    return DocumentState(
      metadata: metadata ?? this.metadata,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      versions: versions ?? this.versions,
      currentVersionIndex: currentVersionIndex ?? this.currentVersionIndex,
      isAIProcessing: isAIProcessing ?? this.isAIProcessing,
      aiResult: clearAIResult ? null : (aiResult ?? this.aiResult),
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      tables: tables ?? this.tables,
      charts: charts ?? this.charts,
      drawings: drawings ?? this.drawings,
      pageSettings: pageSettings ?? this.pageSettings,
      currentLayout: currentLayout ?? this.currentLayout,
      footnotes: footnotes ?? this.footnotes,
      comments: comments ?? this.comments,
      trackedChanges: trackedChanges ?? this.trackedChanges,
      revisionManager: revisionManager ?? this.revisionManager,
      isTrackChangesEnabled:
          isTrackChangesEnabled ?? this.isTrackChangesEnabled,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      collaborators: collaborators ?? this.collaborators,
      isCollaborationEnabled:
          isCollaborationEnabled ?? this.isCollaborationEnabled,
      currentTheme: currentTheme ?? this.currentTheme,
      spellErrors: spellErrors ?? this.spellErrors,
      spellCheckEnabled: spellCheckEnabled ?? this.spellCheckEnabled,
      importStatus: clearImportStatus
          ? const DocumentImportStatus.idle()
          : (importStatus ?? this.importStatus),
      title: title ?? this.title,
      lastModified: lastModified ?? this.lastModified,
      isSaved: isSaved ?? this.isSaved,
      stats: stats ?? this.stats,
      documentId: documentId ?? this.documentId,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
