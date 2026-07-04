# Auto-Save Implementation Guide

## Overview

This guide documents the auto-save implementation added to `ky_docs` to automatically save documents at regular intervals and after user edits, similar to Google Docs and MS Word.

## Architecture

```
User Edits Document
    ↓
Document Change Listener (_onDocumentChanged)
    ↓
AutoSaveService.onDocumentChanged()
    ↓
Debounce Timer (2 seconds)
    ↓
AutoSaveService._performAutoSave()
    ↓
DocumentNotifier.saveDocument()
    ↓
Persistence Service → Storage/Cloud
```

## Components

### 1. AutoSaveService (`lib/docx/states/auto_save_service.dart`)

**Key Features:**
- **Periodic Timer**: Saves every 30 seconds by default
- **Debouncing**: Waits 2 seconds after last edit before saving
- **Smart Saving**: Only saves if there are unsaved changes
- **Error Handling**: Gracefully handles save failures
- **Statistics Tracking**: Monitors save count, last save time, etc.

**Configuration:**
```dart
// Default settings
static const defaultInterval = Duration(seconds: 30);
static const debounceDuration = Duration(seconds: 2);
```

**Public API:**
```dart
void initialize(DocumentNotifier notifier, {Duration? interval})
void onDocumentChanged()
Future<bool> forceSave()
void pause()
void resume({Duration? interval})
void updateInterval(Duration interval)
AutoSaveStats getStats()
void dispose()
```

### 2. DocumentNotifier Integration

**Changes Made:**
1. Added `AutoSaveService` instance as a field
2. Initialize auto-save in constructor
3. Trigger auto-save on document changes
4. Dispose auto-save service on cleanup

**Code Example:**
```dart
final AutoSaveService _autoSaveService = AutoSaveService();

DocumentNotifier(...) {
  state.controller.addListener(_onDocumentChanged);
  _initializeStorage();
  _initializeAutoSave(); // NEW
}

void _initializeAutoSave() {
  _autoSaveService.initialize(this);
}

void _onDocumentChanged() {
  // ... existing change tracking ...

  // NEW: Trigger auto-save debounce timer
  _autoSaveService.onDocumentChanged();
}

@override
void dispose() {
  _collaborationService.dispose();
  _spellCheckOrchestrationService.dispose();
  _autoSaveService.dispose(); // NEW
  // ... rest of disposal ...
}
```

## Usage

### Basic Usage (Automatic)

Auto-save is automatically enabled when a `DocumentNotifier` is created. No additional setup required.

```dart
// In your provider setup
final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
  (ref) => DocumentNotifier(
    storage: ref.read(storageProvider),
    docxService: ref.read(docxServiceProvider),
    pdfService: ref.read(pdfServiceProvider),
    aiService: ref.read(aiAssistantServiceProvider),
    cloudSync: ref.read(cloudSyncServiceProvider),
    collaboration: ref.read(collaborationServiceProvider),
    spellCheck: ref.read(spellCheckServiceProvider),
  ),
);

// Auto-save is now active!
```

### Manual Control

```dart
final notifier = ref.read(documentProvider.notifier);

// Force an immediate save
await notifier.autoSaveService.forceSave();

// Pause auto-save (e.g., during offline mode)
notifier.autoSaveService.pause();

// Resume with custom interval
notifier.autoSaveService.resume(interval: Duration(minutes: 1));

// Get statistics
final stats = notifier.autoSaveService.getStats();
print('Last saved: ${stats.lastSaveTime}');
print('Save count: ${stats.saveCount}');
print('Has unsaved changes: ${stats.hasUnsavedChanges}');
```

### Custom Configuration

```dart
// In DocumentNotifier constructor or initialization
_autoSaveService.initialize(
  this,
  interval: Duration(minutes: 1), // Save every minute instead of 30 seconds
);
```

## UI Indicators

### Save Status Widget

Create a widget to show auto-save status:

```dart
class AutoSaveIndicator extends ConsumerWidget {
  const AutoSaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(autoSaveStatsProvider);

    if (stats.isSaving) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Saving...', style: TextStyle(fontSize: 12)),
        ],
      );
    }

    if (stats.lastSaveTime != null) {
      final elapsed = DateTime.now().difference(stats.lastSaveTime!);
      String timeAgo;

      if (elapsed.inSeconds < 60) {
        timeAgo = '${elapsed.inSeconds}s ago';
      } else if (elapsed.inMinutes < 60) {
        timeAgo = '${elapsed.inMinutes}m ago';
      } else {
        timeAgo = '${elapsed.inHours}h ago';
      }

      return Text(
        'Saved $timeAgo',
        style: TextStyle(
          fontSize: 12,
          color: stats.hasUnsavedChanges ? Colors.orange : Colors.green,
        ),
      );
    }

    return Text('Not saved yet', style: TextStyle(fontSize: 12));
  }
}
```

### Unsaved Changes Warning

Show a warning when user tries to close with unsaved changes:

```dart
Future<bool> _onWillPop() async {
  final stats = ref.read(documentProvider.notifier).autoSaveService.getStats();

  if (stats.hasUnsavedChanges) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  return true;
}
```

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import '../states/auto_save_service.dart';
import '../states/doc_notifier.dart';

void main() {
  test('AutoSaveService initializes correctly', () {
    final service = AutoSaveService();
    final notifier = MockDocumentNotifier();

    service.initialize(notifier);

    expect(service.isEnabled, isTrue);
    expect(service.isSaving, isFalse);
  });

  test('AutoSaveService debounces rapid changes', () async {
    final service = AutoSaveService();
    final notifier = MockDocumentNotifier();

    service.initialize(notifier, interval: Duration(milliseconds: 100));

    // Simulate rapid edits
    for (int i = 0; i < 10; i++) {
      service.onDocumentChanged();
      await Future.delayed(Duration(milliseconds: 50));
    }

    // Should only trigger one save after debouncing
    await Future.delayed(Duration(seconds: 3));

    expect(notifier.saveCallCount, equals(1));
  });

  test('AutoSaveService tracks statistics', () async {
    final service = AutoSaveService();
    final notifier = MockDocumentNotifier();

    service.initialize(notifier);

    await service.forceSave();
    await service.forceSave();

    final stats = service.getStats();
    expect(stats.saveCount, equals(2));
    expect(stats.lastSaveTime, isNotNull);
  });
}
```

### Integration Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auto-save works end-to-end', (tester) async {
    await tester.pumpWidget(MyApp());

    // Type some text
    await tester.enterText(find.byType(Editor), 'Hello World');
    await tester.pump();

    // Wait for debounce + save
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify save indicator appeared
    expect(find.text('Saved'), findsOneWidget);

    // Verify file was saved (check mock storage)
    final savedDoc = MockStorage.getLastSavedDocument();
    expect(savedDoc.content, contains('Hello World'));
  });
}
```

## Troubleshooting

### Issue: Auto-save not triggering

**Solution:**
1. Check if `DocumentNotifier` is properly initialized
2. Verify `_autoSaveService.initialize(this)` is called
3. Ensure document changes are triggering `_onDocumentChanged()`
4. Check debug logs: `debugPrint('Auto-saving document...')`

### Issue: Too many saves happening

**Solution:**
1. Increase debounce duration: `debounceDuration = Duration(seconds: 5)`
2. Increase auto-save interval: `defaultInterval = Duration(minutes: 1)`
3. Verify smart saving is working (only save if `hasUnsavedChanges`)

### Issue: Save failures

**Solution:**
1. Check error messages in `state.errorMessage`
2. Verify storage permissions (especially on mobile)
3. Ensure cloud sync service is properly configured
4. Implement retry logic in `AutoSaveService._performAutoSave()`

### Issue: Memory leaks

**Solution:**
1. Ensure `_autoSaveService.dispose()` is called in `DocumentNotifier.dispose()`
2. Cancel timers properly (already handled in `AutoSaveService.dispose()`)
3. Remove listeners when disposing

## Performance Considerations

### Optimization Tips

1. **Debounce is Critical**: Prevents saving on every keystroke
2. **Smart Saving**: Only save if content actually changed
3. **Async Operations**: All saves are non-blocking
4. **Timer Management**: Properly cancel timers on dispose

### Resource Usage

- **Memory**: Minimal (one timer, few DateTime objects)
- **CPU**: Negligible (timer-based, no polling)
- **Network**: Depends on cloud sync frequency
- **Disk I/O**: Optimized with debouncing

## Future Enhancements

1. **Adaptive Interval**: Adjust save frequency based on edit activity
2. **Offline Queue**: Queue saves when offline, sync when online
3. **Version Snapshots**: Create versions at major milestones
4. **Collaborative Awareness**: Coordinate saves across multiple users
5. **Battery Optimization**: Reduce frequency on low battery
6. **Network Awareness**: Adjust based on connection quality

## Migration from Manual Save

If you're migrating from manual-only save to auto-save:

1. **Keep Manual Save**: Users may still want explicit control
2. **Add UI Indicator**: Show users auto-save is active
3. **Configure Interval**: Start conservative (60 seconds), adjust based on feedback
4. **Test Thoroughly**: Ensure no data loss during transition
5. **Document Behavior**: Inform users about auto-save in help docs

## Related Files

- `lib/docx/states/auto_save_service.dart` - Core auto-save service (NEW)
- `lib/docx/states/doc_notifier.dart` - Integrated with DocumentNotifier (MODIFIED)
- `lib/docx/widgets/widgets/save_indicator.dart` - UI indicator (existing)
- `lib/docx/models/document_state.dart` - State model (may need auto-save fields)

## See Also

- [File Menu Integration Guide](FILE_MENU_INTEGRATION_FIX.md)
- [Import/Export Guide](IMPORT_EXPORT_GUIDE.md)
- [Sample Document Test Guide](SAMPLE_DOCUMENT_TEST_GUIDE.md)