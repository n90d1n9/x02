import 'package:flutter/widgets.dart';

/// Tracks command row contexts so the palette can reveal the active result.
class DocumentCommandTileRegistry {
  final _keysByCommandId = <String, GlobalKey>{};

  GlobalKey keyFor(String commandId) {
    return _keysByCommandId.putIfAbsent(
      commandId,
      () => GlobalKey(debugLabel: 'document-command-result-$commandId'),
    );
  }

  BuildContext? contextFor(String? commandId) {
    if (commandId == null) return null;
    return _keysByCommandId[commandId]?.currentContext;
  }

  void retainCommandIds(Iterable<String> commandIds) {
    final visibleIds = commandIds.toSet();
    _keysByCommandId.removeWhere(
      (commandId, _) => !visibleIds.contains(commandId),
    );
  }
}
