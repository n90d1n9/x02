import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/document_state.dart';
import 'doc_notifier.dart';

/// Service that handles automatic saving of documents with configurable intervals
/// and debouncing to prevent excessive saves during active editing.
class AutoSaveService {
  /// Default auto-save interval in milliseconds (30 seconds)
  static const defaultInterval = Duration(seconds: 30);
  
  /// Debounce duration to wait after last edit before triggering save (2 seconds)
  static const debounceDuration = Duration(seconds: 2);
  
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  DocumentNotifier? _notifier;
  bool _isEnabled = false;
  bool _isSaving = false;
  DateTime? _lastSaveTime;
  int _saveCount = 0;
  
  /// Whether auto-save is currently enabled
  bool get isEnabled => _isEnabled;
  
  /// Whether a save operation is currently in progress
  bool get isSaving => _isSaving;
  
  /// The time when the last successful save occurred
  DateTime? get lastSaveTime => _lastSaveTime;
  
  /// Total number of successful auto-saves
  int get saveCount => _saveCount;
  
  /// Last time content was modified
  DateTime? _lastModifiedTime;
  
  /// Initialize the auto-save service with a document notifier
  void initialize(DocumentNotifier notifier, {Duration? interval}) {
    _notifier = notifier;
    _isEnabled = true;
    
    // Start the auto-save timer
    _startAutoSaveTimer(interval ?? defaultInterval);
    
    debugPrint('AutoSaveService initialized with interval: ${interval ?? defaultInterval}');
  }
  
  /// Start or restart the auto-save timer
  void _startAutoSaveTimer(Duration interval) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(interval, (_) => _performAutoSave());
  }
  
  /// Called when document content changes - triggers debounced save
  void onDocumentChanged() {
    if (!_isEnabled || _notifier == null) return;
    
    _lastModifiedTime = DateTime.now();
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    // Start a new debounce timer
    _debounceTimer = Timer(debounceDuration, () {
      _triggerImmediateSave();
    });
  }
  
  /// Trigger an immediate save (used after debounce or manual save request)
  Future<void> _triggerImmediateSave() async {
    if (_isSaving || _notifier == null) return;
    
    await _performAutoSave();
  }
  
  /// Perform the actual auto-save operation
  Future<void> _performAutoSave() async {
    if (_isSaving || _notifier == null || !_isEnabled) return;
    
    // Check if there are unsaved changes
    final state = _notifier!.state;
    if (!state.hasUnsavedChanges && _lastSaveTime != null) {
      // No changes since last save, skip
      return;
    }
    
    _isSaving = true;
    
    try {
      debugPrint('Auto-saving document...');
      
      // Save the document
      await _notifier!.saveDocument();
      
      _lastSaveTime = DateTime.now();
      _saveCount++;
      
      debugPrint('Auto-save completed successfully (${_saveCount} total saves)');
      
      // Notify listeners of save status change
      _notifier!.state = state.copyWith(
        lastSavedAt: _lastSaveTime,
        autoSaveCount: _saveCount,
      );
    } catch (e) {
      debugPrint('Auto-save failed: $e');
      
      // Update error state
      _notifier!.state = state.copyWith(
        errorMessage: 'Auto-save failed: $e',
      );
    } finally {
      _isSaving = false;
    }
  }
  
  /// Manually trigger an auto-save (useful for testing or forced saves)
  Future<bool> forceSave() async {
    if (_notifier == null) return false;
    
    await _performAutoSave();
    return !_isSaving;
  }
  
  /// Pause auto-saving temporarily (e.g., during offline mode)
  void pause() {
    _isEnabled = false;
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    debugPrint('AutoSaveService paused');
  }
  
  /// Resume auto-saving after being paused
  void resume({Duration? interval}) {
    if (_notifier == null) return;
    
    _isEnabled = true;
    _startAutoSaveTimer(interval ?? defaultInterval);
    debugPrint('AutoSaveService resumed');
  }
  
  /// Update the auto-save interval
  void updateInterval(Duration interval) {
    if (!_isEnabled) return;
    _startAutoSaveTimer(interval);
    debugPrint('AutoSaveService interval updated to: $interval');
  }
  
  /// Get statistics about auto-save activity
  AutoSaveStats getStats() {
    return AutoSaveStats(
      isEnabled: _isEnabled,
      isSaving: _isSaving,
      lastSaveTime: _lastSaveTime,
      lastModifiedTime: _lastModifiedTime,
      saveCount: _saveCount,
      hasUnsavedChanges: _notifier?.state.hasUnsavedChanges ?? false,
    );
  }
  
  /// Dispose of timers and clean up resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    _notifier = null;
    _isEnabled = false;
    debugPrint('AutoSaveService disposed');
  }
}

/// Statistics about auto-save activity
class AutoSaveStats {
  final bool isEnabled;
  final bool isSaving;
  final DateTime? lastSaveTime;
  final DateTime? lastModifiedTime;
  final int saveCount;
  final bool hasUnsavedChanges;
  
  const AutoSaveStats({
    required this.isEnabled,
    required this.isSaving,
    this.lastSaveTime,
    this.lastModifiedTime,
    required this.saveCount,
    required this.hasUnsavedChanges,
  });
  
  /// Time elapsed since last save
  Duration? get timeSinceLastSave() {
    if (lastSaveTime == null) return null;
    return DateTime.now().difference(lastSaveTime!);
  }
  
  /// Time elapsed since last modification
  Duration? get timeSinceLastModification() {
    if (lastModifiedTime == null) return null;
    return DateTime.now().difference(lastModifiedTime!);
  }
  
  /// Whether document needs saving
  bool get needsSave => hasUnsavedChanges || lastModifiedTime == null;
}
