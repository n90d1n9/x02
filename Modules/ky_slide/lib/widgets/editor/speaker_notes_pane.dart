import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/speaker_notes_metrics.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/slide_property_actions_provider.dart';
import 'speaker_notes_editor.dart';

/// Provider-backed adapter that edits and persists notes for the active slide.
class SpeakerNotesPane extends ConsumerStatefulWidget {
  const SpeakerNotesPane({super.key});

  @override
  ConsumerState<SpeakerNotesPane> createState() => _SpeakerNotesPaneState();
}

/// Synchronizes note editing state with the currently selected slide.
class _SpeakerNotesPaneState extends ConsumerState<SpeakerNotesPane> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final SlidePropertyActions _slideActions;
  String? _slideId;

  @override
  void initState() {
    super.initState();
    _slideActions = ref.read(slidePropertyActionsProvider);
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_commitWhenFocusLeaves);
  }

  @override
  void dispose() {
    _commitNotes();
    _focusNode
      ..removeListener(_commitWhenFocusLeaves)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    if (_slideId != currentSlide.id) {
      _slideId = currentSlide.id;
      _controller.text = currentSlide.notes ?? '';
    }

    final notes = _controller.text;
    final metrics = SpeakerNotesMetrics.fromText(notes);

    return SpeakerNotesEditor(
      slideNumber: presentation.currentSlideIndex + 1,
      slideTitle: currentSlide.title ?? '',
      metrics: metrics,
      canClear: notes.trim().isNotEmpty,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: (_) => setState(() {}),
      onClear: _clearNotes,
      onClose: _hideNotes,
    );
  }

  void _commitWhenFocusLeaves() {
    if (!_focusNode.hasFocus) {
      _commitNotes();
    }
  }

  void _commitNotes() {
    _slideActions.updateSpeakerNotes(_controller.text);
  }

  void _clearNotes() {
    _controller.clear();
    setState(() {});
    _commitNotes();
  }

  void _hideNotes() {
    _commitNotes();
    ref.read(speakerNotesVisibleProvider.notifier).state = false;
  }
}

@Preview(name: 'Speaker notes pane', size: Size(760, 180))
Widget speakerNotesPanePreview() {
  return const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SpeakerNotesPane()),
    ),
  );
}
