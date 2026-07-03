import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable workbook-level keyboard shortcut layer for spreadsheet screens.
class SheetWorkbookShortcuts extends StatelessWidget {
  const SheetWorkbookShortcuts({
    super.key,
    required this.child,
    required this.onOpenFindReplace,
    required this.onOpenReplace,
    required this.onOpenSortFilter,
    required this.onOpenCommandPalette,
    required this.onOpenShortcuts,
    required this.onCloseActivePanel,
    required this.onPreviousSheet,
    required this.onNextSheet,
  });

  final Widget child;
  final VoidCallback onOpenFindReplace;
  final VoidCallback onOpenReplace;
  final VoidCallback onOpenSortFilter;
  final VoidCallback onOpenCommandPalette;
  final VoidCallback onOpenShortcuts;
  final bool Function() onCloseActivePanel;
  final VoidCallback onPreviousSheet;
  final VoidCallback onNextSheet;

  @override
  Widget build(BuildContext context) {
    return Focus(autofocus: true, onKeyEvent: _handleKeyEvent, child: child);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (_isReplaceShortcut(event, pressed)) {
      onOpenReplace();
      return KeyEventResult.handled;
    }

    if (_isFindReplaceShortcut(event, pressed)) {
      onOpenFindReplace();
      return KeyEventResult.handled;
    }

    if (_isSortFilterShortcut(event, pressed)) {
      onOpenSortFilter();
      return KeyEventResult.handled;
    }

    if (_isCommandPaletteShortcut(event, pressed)) {
      onOpenCommandPalette();
      return KeyEventResult.handled;
    }

    if (_isShortcutsPanelShortcut(event, pressed)) {
      onOpenShortcuts();
      return KeyEventResult.handled;
    }

    if (_isHelpShortcut(event, pressed)) {
      onOpenShortcuts();
      return KeyEventResult.handled;
    }

    if (_isClosePanelShortcut(event, pressed) && onCloseActivePanel()) {
      return KeyEventResult.handled;
    }

    if (_isPreviousSheetShortcut(event, pressed)) {
      onPreviousSheet();
      return KeyEventResult.handled;
    }

    if (_isNextSheetShortcut(event, pressed)) {
      onNextSheet();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  static bool _isReplaceShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return _hasCommandModifier(pressed) &&
        event.logicalKey == LogicalKeyboardKey.keyH;
  }

  static bool _isFindReplaceShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return _hasCommandModifier(pressed) &&
        event.logicalKey == LogicalKeyboardKey.keyF;
  }

  static bool _isSortFilterShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return _hasCommandModifier(pressed) &&
        _hasShift(pressed) &&
        event.logicalKey == LogicalKeyboardKey.keyL;
  }

  static bool _isCommandPaletteShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return _hasCommandModifier(pressed) &&
        event.logicalKey == LogicalKeyboardKey.keyK;
  }

  static bool _isShortcutsPanelShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return _hasCommandModifier(pressed) &&
        event.logicalKey == LogicalKeyboardKey.slash;
  }

  static bool _isHelpShortcut(KeyEvent event, Set<LogicalKeyboardKey> pressed) {
    return !_hasCommandModifier(pressed) &&
        !_hasShift(pressed) &&
        !_hasAlt(pressed) &&
        event.logicalKey == LogicalKeyboardKey.f1;
  }

  static bool _isClosePanelShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return !_hasCommandModifier(pressed) &&
        !_hasShift(pressed) &&
        !_hasAlt(pressed) &&
        event.logicalKey == LogicalKeyboardKey.escape;
  }

  static bool _isPreviousSheetShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return (_hasControl(pressed) &&
            event.logicalKey == LogicalKeyboardKey.pageUp) ||
        (_hasMeta(pressed) &&
            _hasShift(pressed) &&
            event.logicalKey == LogicalKeyboardKey.bracketLeft);
  }

  static bool _isNextSheetShortcut(
    KeyEvent event,
    Set<LogicalKeyboardKey> pressed,
  ) {
    return (_hasControl(pressed) &&
            event.logicalKey == LogicalKeyboardKey.pageDown) ||
        (_hasMeta(pressed) &&
            _hasShift(pressed) &&
            event.logicalKey == LogicalKeyboardKey.bracketRight);
  }

  static bool _hasCommandModifier(Set<LogicalKeyboardKey> pressed) {
    return _hasControl(pressed) || _hasMeta(pressed);
  }

  static bool _hasControl(Set<LogicalKeyboardKey> pressed) {
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  static bool _hasMeta(Set<LogicalKeyboardKey> pressed) {
    return pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
  }

  static bool _hasShift(Set<LogicalKeyboardKey> pressed) {
    return pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
  }

  static bool _hasAlt(Set<LogicalKeyboardKey> pressed) {
    return pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);
  }
}
