import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentEditorShortcuts extends StatelessWidget {
  final bool canSave;
  final Future<void> Function() onSave;
  final VoidCallback onToggleFindReplace;
  final VoidCallback onShowFindReplace;
  final VoidCallback onOpenCommandPalette;
  final Future<void> Function() onPrint;
  final Future<void> Function() onCreateNewDocument;
  final Widget child;

  const DocumentEditorShortcuts({
    super.key,
    required this.canSave,
    required this.onSave,
    required this.onToggleFindReplace,
    required this.onShowFindReplace,
    required this.onOpenCommandPalette,
    required this.onPrint,
    required this.onCreateNewDocument,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (canSave) {
            unawaited(onSave());
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            onToggleFindReplace,
        const SingleActivator(LogicalKeyboardKey.keyH, control: true):
            onShowFindReplace,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            onOpenCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            onOpenCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          unawaited(onPrint());
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          unawaited(onCreateNewDocument());
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
