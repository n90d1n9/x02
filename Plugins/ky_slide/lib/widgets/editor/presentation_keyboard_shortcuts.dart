import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/component_layer_actions_provider.dart';
import '../../states/component_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/history_provider.dart';

/// Editor-level commands that can be invoked from keyboard shortcuts.
enum PresentationShortcutCommand {
  openCommandPalette,
  deleteSelectedLayer,
  duplicateSelectedLayer,
  undo,
  redo,
  enterPresenterMode,
  bringSelectedLayerToFront,
  moveSelectedLayerForward,
  moveSelectedLayerBackward,
  sendSelectedLayerToBack,
  nudgeSelectedLayer,
}

/// Shortcut intent carrying an editor command and optional nudge metadata.
class PresentationShortcutIntent extends Intent {
  final PresentationShortcutCommand command;
  final Offset nudgeDirection;
  final bool isLargeNudge;

  /// Intent payload used by the editor shortcut dispatcher.
  const PresentationShortcutIntent(
    this.command, {
    this.nudgeDirection = Offset.zero,
    this.isLargeNudge = false,
  });
}

/// Registers keyboard shortcuts for global editor and selected-object actions.
class PresentationKeyboardShortcuts extends ConsumerWidget {
  final Widget child;

  const PresentationKeyboardShortcuts({super.key, required this.child});

  static const shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.delete): PresentationShortcutIntent(
      PresentationShortcutCommand.deleteSelectedLayer,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyK,
      control: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.openCommandPalette,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyK,
      meta: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.openCommandPalette,
    ),
    SingleActivator(LogicalKeyboardKey.backspace): PresentationShortcutIntent(
      PresentationShortcutCommand.deleteSelectedLayer,
    ),
    SingleActivator(LogicalKeyboardKey.arrowUp): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(0, -1),
    ),
    SingleActivator(LogicalKeyboardKey.arrowDown): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(0, 1),
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(-1, 0),
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(1, 0),
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowUp,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(0, -1),
      isLargeNudge: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowDown,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(0, 1),
      isLargeNudge: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowLeft,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(-1, 0),
      isLargeNudge: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowRight,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.nudgeSelectedLayer,
      nudgeDirection: Offset(1, 0),
      isLargeNudge: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyD,
      control: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.duplicateSelectedLayer,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyD,
      meta: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.duplicateSelectedLayer,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketRight,
      control: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.moveSelectedLayerForward,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketRight,
      meta: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.moveSelectedLayerForward,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      control: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.moveSelectedLayerBackward,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      meta: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.moveSelectedLayerBackward,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketRight,
      control: true,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.bringSelectedLayerToFront,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketRight,
      meta: true,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.bringSelectedLayerToFront,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      control: true,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.sendSelectedLayerToBack,
    ),
    SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      meta: true,
      shift: true,
    ): PresentationShortcutIntent(
      PresentationShortcutCommand.sendSelectedLayerToBack,
    ),
    SingleActivator(LogicalKeyboardKey.keyZ, control: true):
        PresentationShortcutIntent(PresentationShortcutCommand.undo),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
        PresentationShortcutIntent(PresentationShortcutCommand.undo),
    SingleActivator(LogicalKeyboardKey.keyY, control: true):
        PresentationShortcutIntent(PresentationShortcutCommand.redo),
    SingleActivator(LogicalKeyboardKey.keyY, meta: true):
        PresentationShortcutIntent(PresentationShortcutCommand.redo),
    SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
        PresentationShortcutIntent(PresentationShortcutCommand.redo),
    SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
        PresentationShortcutIntent(PresentationShortcutCommand.redo),
    SingleActivator(LogicalKeyboardKey.f5): PresentationShortcutIntent(
      PresentationShortcutCommand.enterPresenterMode,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatcher = _PresentationShortcutDispatcher(ref);

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          PresentationShortcutIntent:
              CallbackAction<PresentationShortcutIntent>(
                onInvoke: (intent) {
                  dispatcher.invoke(intent);
                  return null;
                },
              ),
        },
        child: Focus(
          autofocus: true,
          debugLabel: 'Presentation editor shortcuts',
          child: child,
        ),
      ),
    );
  }
}

class _PresentationShortcutDispatcher {
  final WidgetRef ref;

  const _PresentationShortcutDispatcher(this.ref);

  void invoke(PresentationShortcutIntent intent) {
    switch (intent.command) {
      case PresentationShortcutCommand.openCommandPalette:
        ref.read(commandPaletteVisibleProvider.notifier).state = true;
        break;
      case PresentationShortcutCommand.deleteSelectedLayer:
        ref.read(componentLayerActionsProvider).deleteSelectedLayer();
        break;
      case PresentationShortcutCommand.duplicateSelectedLayer:
        ref.read(componentLayerActionsProvider).duplicateSelectedLayer();
        break;
      case PresentationShortcutCommand.undo:
        ref.read(historyProvider.notifier).undo();
        break;
      case PresentationShortcutCommand.redo:
        ref.read(historyProvider.notifier).redo();
        break;
      case PresentationShortcutCommand.enterPresenterMode:
        ref.read(presenterModeProvider.notifier).state = true;
        break;
      case PresentationShortcutCommand.bringSelectedLayerToFront:
        ref.read(componentLayerActionsProvider).bringSelectedLayerToFront();
        break;
      case PresentationShortcutCommand.moveSelectedLayerForward:
        ref.read(componentLayerActionsProvider).moveSelectedLayerForward();
        break;
      case PresentationShortcutCommand.moveSelectedLayerBackward:
        ref.read(componentLayerActionsProvider).moveSelectedLayerBackward();
        break;
      case PresentationShortcutCommand.sendSelectedLayerToBack:
        ref.read(componentLayerActionsProvider).sendSelectedLayerToBack();
        break;
      case PresentationShortcutCommand.nudgeSelectedLayer:
        ref
            .read(componentLayerActionsProvider)
            .nudgeSelectedLayer(
              intent.nudgeDirection,
              isLargeStep: intent.isLargeNudge,
            );
        break;
    }
  }
}
