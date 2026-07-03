// Undo/Redo History
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';

import '../models/history_entry.dart';
import '../models/presentation.dart';
import 'presentation_provider.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  return HistoryNotifier(ref);
});

class HistoryState {
  final List<HistoryEntry> entries;
  final int currentIndex;

  HistoryState({
    List<HistoryEntry>? entries,
    List<Presentation>? states,
    required this.currentIndex,
  }) : entries = List.unmodifiable(
         entries ??
             states?.map((presentation) {
               return HistoryEntry(presentation: presentation);
             }) ??
             const <HistoryEntry>[],
       );

  List<Presentation> get states {
    return entries.map((entry) => entry.presentation).toList(growable: false);
  }

  bool get canUndo => currentIndex > 0;
  bool get canRedo => currentIndex < entries.length - 1;
  String? get undoLabel => canUndo ? entries[currentIndex].label : null;
  String? get redoLabel => canRedo ? entries[currentIndex + 1].label : null;
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  static const _maxHistoryStates = 50;

  final Ref ref;

  HistoryNotifier(this.ref) : super(HistoryState(states: [], currentIndex: -1));

  void addState(Presentation presentation, {String? label}) {
    final entries = _activeEntries();
    if (entries.isNotEmpty &&
        identical(entries.last.presentation, presentation)) {
      return;
    }

    entries.add(HistoryEntry(presentation: presentation, label: label));
    _commit(entries);
  }

  void recordChange({
    required Presentation before,
    required Presentation after,
    String? label,
  }) {
    if (identical(before, after)) {
      return;
    }

    final entries = _activeEntries();
    if (entries.isEmpty || !identical(entries.last.presentation, before)) {
      entries.add(HistoryEntry(presentation: before));
    }
    if (!identical(entries.last.presentation, after)) {
      entries.add(HistoryEntry(presentation: after, label: label));
    }

    _commit(entries);
  }

  void recordPresentationMutation(
    void Function(PresentationNotifier notifier) mutate, {
    String? label,
  }) {
    final before = ref.read(presentationProvider);
    mutate(ref.read(presentationProvider.notifier));
    final after = ref.read(presentationProvider);

    recordChange(before: before, after: after, label: label);
  }

  void undo() {
    if (state.canUndo) {
      final newIndex = state.currentIndex - 1;
      ref
          .read(presentationProvider.notifier)
          .loadPresentation(state.entries[newIndex].presentation);
      state = HistoryState(entries: state.entries, currentIndex: newIndex);
    }
  }

  void redo() {
    if (state.canRedo) {
      final newIndex = state.currentIndex + 1;
      ref
          .read(presentationProvider.notifier)
          .loadPresentation(state.entries[newIndex].presentation);
      state = HistoryState(entries: state.entries, currentIndex: newIndex);
    }
  }

  void jumpTo(int index) {
    if (index < 0 || index >= state.entries.length) {
      return;
    }
    if (index == state.currentIndex) {
      return;
    }

    ref
        .read(presentationProvider.notifier)
        .loadPresentation(state.entries[index].presentation);
    state = HistoryState(entries: state.entries, currentIndex: index);
  }

  List<HistoryEntry> _activeEntries() {
    if (state.currentIndex < state.entries.length - 1) {
      return state.entries.sublist(0, state.currentIndex + 1);
    }

    return List<HistoryEntry>.from(state.entries);
  }

  void _commit(List<HistoryEntry> entries) {
    while (entries.length > _maxHistoryStates) {
      entries.removeAt(0);
    }

    state = HistoryState(
      entries: entries,
      currentIndex: entries.isEmpty ? -1 : entries.length - 1,
    );
  }
}
