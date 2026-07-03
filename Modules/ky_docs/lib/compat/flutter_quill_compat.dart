// Compatibility shim to replace flutter_quill with internal document canvas implementation.
// Provides minimal API surface used across ky_docs so the app compiles while
// native Document canvas integration is used at runtime.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'quill_delta.dart';
export 'quill_delta.dart' show Delta;

class FlutterQuillLocalizations {
  const FlutterQuillLocalizations();
  static const LocalizationsDelegate<FlutterQuillLocalizations> delegate = _FlutterQuillLocalizationsDelegate();
}

class _FlutterQuillLocalizationsDelegate extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const _FlutterQuillLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) => SynchronousFuture(const FlutterQuillLocalizations());

  @override
  bool shouldReload(LocalizationsDelegate<FlutterQuillLocalizations> old) => false;
}


// Minimal Document model used by QuillController
class Document {
  final List<Map<String, Object?>> _ops = [];
  Document();
  factory Document.fromDelta(Delta delta) {
    final doc = Document();
    return doc;
  }
  factory Document.fromJson(Object? json) => Document();

  Delta toDelta() => Delta.fromOps(_ops);
  String toPlainText() => '';

  // Minimal editable methods
  int get length => 0;
  void insert(int index, Object data) {}
  void delete(int index, int length) {}
}

class QuillStyle {
  final Map<String, Attribute> attributes;
  QuillStyle([Map<String, Attribute>? attrs]) : attributes = attrs ?? {};
}

class Attribute {
  final String key;
  final Object? value;
  const Attribute(this.key, this.value);

  static const Attribute bold = Attribute('bold', true);
  static const Attribute italic = Attribute('italic', true);
  static const Attribute underline = Attribute('underline', true);
  static const Attribute strikeThrough = Attribute('strike', true);
  static const Attribute inlineCode = Attribute('code', true);
  static const Attribute blockQuote = Attribute('blockquote', true);
  static const Attribute codeBlock = Attribute('code-block', true);
  static const Attribute header = Attribute('header', 1);
  static const Attribute h1 = Attribute('header', 1);
  static const Attribute h2 = Attribute('header', 2);
  static const Attribute h3 = Attribute('header', 3);
  static const Attribute list = Attribute('list', 'bullet');
  static const Attribute ol = Attribute('list', 'ordered');
  static const Attribute ul = Attribute('list', 'bullet');
  static const Attribute checked = Attribute('checked', true);
  static const Attribute unchecked = Attribute('checked', false);

  // Additional attributes referenced in UI
  static const Attribute size = Attribute('size', null);
  static const Attribute font = Attribute('font', null);
  static const Attribute background = Attribute('background', null);
  static const Attribute color = Attribute('color', null);
  static const Attribute link = Attribute('link', null);
  static const Attribute align = Attribute('align', null);
  static const Attribute indent = Attribute('indent', null);
  static const Attribute direction = Attribute('direction', null);
  static const Attribute lineHeight = Attribute('lineHeight', null);
  static const Attribute script = Attribute('script', null);

  static Attribute clone(Attribute attr, Object? val) => Attribute(attr.key, val);
}

class QuillController extends ChangeNotifier {
  QuillController({Document? document, TextSelection? selection, bool readOnly = false}) : _document = document ?? Document(), _readOnly = readOnly {
    if (selection != null) this.selection = selection;
  }

  QuillController.basic() : _document = Document(), _readOnly = false;

  Document _document;
  TextSelection selection = const TextSelection.collapsed(offset: 0);
  bool _readOnly = false;

  bool get readOnly => _readOnly;
  set readOnly(bool val) => _readOnly = val;

  Document get document => _document;

  void replaceText(int index, int length, Object data, TextSelection? selection) {}
  void updateSelection(TextSelection selection, dynamic source) { this.selection = selection; }
  QuillStyle getSelectionStyle() => QuillStyle();
  void formatSelection(Attribute attribute) {}
  void formatText(int index, int length, Attribute attribute) {}
  void dispose() { super.dispose(); }
}

// Editor config and widget
class QuillEditorConfig {
  final FocusNode? focusNode;
  final EdgeInsets? padding;
  final dynamic customStyles;
  final String? placeholder;
  final bool readOnly;
  final ScrollController? scrollController;
  final bool scrollable;
  final bool autoFocus;
  final bool expands;

  const QuillEditorConfig({this.focusNode, this.padding, this.customStyles, this.placeholder, this.readOnly = false, this.scrollController, this.scrollable = true, this.autoFocus = false, this.expands = false});
}

class QuillEditor extends StatelessWidget {
  final QuillController? controller;
  final QuillEditorConfig? config;
  final bool readOnly;
  final FocusNode? focusNode;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool scrollable;
  final bool autoFocus;
  final bool expands;

  const QuillEditor._({this.controller, this.config, this.readOnly = false, this.focusNode, this.padding, this.scrollController, this.scrollable = true, this.autoFocus = false, this.expands = false, Key? key}) : super(key: key);

  factory QuillEditor.basic({Key? key, QuillEditorConfig? config, required QuillController controller, FocusNode? focusNode, ScrollController? scrollController, bool scrollable = true, bool autoFocus = false, EdgeInsets? padding, bool readOnly = false, bool expands = false}) {
    return QuillEditor._(controller: controller, config: config, readOnly: readOnly, focusNode: focusNode, padding: padding, scrollController: scrollController, scrollable: scrollable, autoFocus: autoFocus, expands: expands, key: key);
  }

  @override
  Widget build(BuildContext context) {
    // Render a placeholder; real document canvas will be mounted elsewhere.
    return Container(color: Colors.transparent);
  }
}

// Toolbar placeholder widgets and option classes
class QuillToolbarHistoryButtonOptions { final bool? isUndo; const QuillToolbarHistoryButtonOptions({this.isUndo}); }
class QuillToolbarToggleStyleButtonOptions { final String? tooltip; const QuillToolbarToggleStyleButtonOptions({this.tooltip}); }
class QuillToolbarFontFamilyButtonOptions { final String? tooltip; const QuillToolbarFontFamilyButtonOptions({this.tooltip}); }
class QuillToolbarFontSizeButtonOptions { final String? tooltip; const QuillToolbarFontSizeButtonOptions({this.tooltip}); }
class QuillToolbarColorButtonOptions { final bool? isBackground; const QuillToolbarColorButtonOptions({this.isBackground}); }
class QuillToolbarSelectHeaderStyleDropdownButtonOptions { const QuillToolbarSelectHeaderStyleDropdownButtonOptions(); }
class QuillToolbarIndentButtonOptions { final bool? isIncrease; const QuillToolbarIndentButtonOptions({this.isIncrease}); }
class QuillToolbarLinkStyleButtonOptions { const QuillToolbarLinkStyleButtonOptions(); }
class QuillToolbarClearFormatButtonOptions { const QuillToolbarClearFormatButtonOptions(); }
class QuillSimpleToolbarConfig {
  final bool? multiRowsDisplay;
  final bool? showAlignmentButtons;
  final bool? showBackgroundColorButton;
  final bool? showCenterAlignment;
  final bool? showCodeBlock;
  final bool? showColorButton;
  final bool? showDirection;
  final bool? showFontSize;
  final bool? showHeaderStyle;
  final bool? showIndent;
  final bool? showInlineCode;
  final bool? showLink;
  final bool? showListCheck;
  final bool? showQuote;
  final bool? showSearchButton;
  final bool? showStrikeThrough;
  final bool? showSubscript;
  final bool? showSuperscript;

  const QuillSimpleToolbarConfig({
    this.multiRowsDisplay,
    this.showAlignmentButtons,
    this.showBackgroundColorButton,
    this.showCenterAlignment,
    this.showCodeBlock,
    this.showColorButton,
    this.showDirection,
    this.showFontSize,
    this.showHeaderStyle,
    this.showIndent,
    this.showInlineCode,
    this.showLink,
    this.showListCheck,
    this.showQuote,
    this.showSearchButton,
    this.showStrikeThrough,
    this.showSubscript,
    this.showSuperscript,
  });
}

class QuillToolbarHistoryButton extends StatelessWidget {
  final QuillToolbarHistoryButtonOptions? options;
  final dynamic controller;
  final bool? isUndo;
  const QuillToolbarHistoryButton({this.options, this.controller, this.isUndo, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarToggleStyleButton extends StatelessWidget {
  final QuillToolbarToggleStyleButtonOptions? options;
  final Attribute? attribute;
  final dynamic controller;
  const QuillToolbarToggleStyleButton({this.options, this.attribute, this.controller, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarFontFamilyButton extends StatelessWidget {
  final dynamic controller;
  final QuillToolbarFontFamilyButtonOptions? options;
  const QuillToolbarFontFamilyButton({this.controller, this.options, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarFontSizeButton extends StatelessWidget {
  final dynamic controller;
  final QuillToolbarFontSizeButtonOptions? options;
  const QuillToolbarFontSizeButton({this.controller, this.options, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarColorButton extends StatelessWidget {
  final dynamic controller;
  final QuillToolbarColorButtonOptions? options;
  final bool? isBackground;
  const QuillToolbarColorButton({this.controller, this.options, this.isBackground, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarSelectHeaderStyleDropdownButton extends StatelessWidget {
  final QuillToolbarSelectHeaderStyleDropdownButtonOptions? options;
  final dynamic controller;
  const QuillToolbarSelectHeaderStyleDropdownButton({this.options, this.controller, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarIndentButton extends StatelessWidget {
  final QuillToolbarIndentButtonOptions? options;
  final dynamic controller;
  final bool? isIncrease;
  const QuillToolbarIndentButton({this.options, this.controller, this.isIncrease, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarLinkStyleButton extends StatelessWidget {
  final dynamic options;
  final dynamic controller;
  const QuillToolbarLinkStyleButton({this.options, this.controller, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillToolbarClearFormatButton extends StatelessWidget {
  final dynamic options;
  final dynamic controller;
  const QuillToolbarClearFormatButton({this.options, this.controller, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class QuillSimpleToolbar extends StatelessWidget {
  final QuillSimpleToolbarConfig? config;
  final dynamic controller;
  final bool? multiRowsDisplay;
  const QuillSimpleToolbar({this.config, this.controller, this.multiRowsDisplay, Key? key}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class HorizontalSpacing { const HorizontalSpacing(double a, double b); }
class VerticalSpacing { const VerticalSpacing(double a, double b); }

class DefaultTextBlockStyle {
  final TextStyle style;
  final HorizontalSpacing horizontalSpacing;
  final VerticalSpacing verticalSpacing1;
  final VerticalSpacing verticalSpacing2;
  final Decoration decoration;
  const DefaultTextBlockStyle(this.style, this.horizontalSpacing, this.verticalSpacing1, this.verticalSpacing2, this.decoration);
}

class DefaultStyles {
  final DefaultTextBlockStyle? placeHolder;
  const DefaultStyles({this.placeHolder});
}

enum ChangeSource { local, remote }
