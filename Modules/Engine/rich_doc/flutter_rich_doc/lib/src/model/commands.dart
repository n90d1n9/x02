/// Typed builders for the JSON commands `rich_doc_ffi::apply_command`
/// expects. This is the *only* file that knows the wire shape of a
/// `Command`/`Op` — every other Dart layer (state, rendering, editing)
/// goes through these classes instead of building JSON maps by hand.
///
/// Kept as plain `toJson()` methods rather than a codegen'd
/// (freezed/json_serializable) model on purpose: the wire format is
/// small and stable (see `rich_doc_core::agent::describe_schema`), and
/// a hand-written mapping here means there's no build_runner step
/// between "I added a case in Rust" and "Dart can send it" — you edit
/// two files, not run a generator.
library rich_doc_model;

import 'dart:convert' show jsonEncode;

/// A node id as returned by Rust. Kept as a thin wrapper (not a bare
/// `int`) so it can't be accidentally swapped with an offset or a
/// mark-range boundary at a call site — the type system catches it.
class NodeId {
  final int value;
  const NodeId(this.value);

  factory NodeId.fromJson(dynamic json) => NodeId(json as int);
  int toJson() => value;

  @override
  bool operator ==(Object other) => other is NodeId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'NodeId($value)';
}

/// Inline formatting. Mirrors `rich_doc_core::schema::Mark`.
sealed class Mark {
  Map<String, dynamic> toJson();

  static Mark fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'bold':
        return const BoldMark();
      case 'italic':
        return const ItalicMark();
      case 'underline':
        return const UnderlineMark();
      case 'strike':
        return const StrikeMark();
      case 'code':
        return const CodeMark();
      case 'link':
        return LinkMark(json['href'] as String);
      case 'custom':
        return CustomMark(json['name'] as String, Map<String, dynamic>.from(json['attrs'] as Map? ?? {}));
      default:
        throw FormatException('unknown mark type: ${json['type']}');
    }
  }
}

class BoldMark extends Mark {
  const BoldMark();
  @override
  Map<String, dynamic> toJson() => {'type': 'bold'};
}

class ItalicMark extends Mark {
  const ItalicMark();
  @override
  Map<String, dynamic> toJson() => {'type': 'italic'};
}

class UnderlineMark extends Mark {
  const UnderlineMark();
  @override
  Map<String, dynamic> toJson() => {'type': 'underline'};
}

class StrikeMark extends Mark {
  const StrikeMark();
  @override
  Map<String, dynamic> toJson() => {'type': 'strike'};
}

class CodeMark extends Mark {
  const CodeMark();
  @override
  Map<String, dynamic> toJson() => {'type': 'code'};
}

class LinkMark extends Mark {
  final String href;
  const LinkMark(this.href);
  @override
  Map<String, dynamic> toJson() => {'type': 'link', 'href': href};
}

class CustomMark extends Mark {
  final String name;
  final Map<String, dynamic> attrs;
  const CustomMark(this.name, this.attrs);
  @override
  Map<String, dynamic> toJson() => {'type': 'custom', 'name': name, 'attrs': attrs};
}

/// A mark *tag* (no payload) — used to remove a mark by kind.
/// Mirrors `rich_doc_core::schema::MarkTag`.
class MarkTag {
  final String tag; // "bold" | "italic" | ... | custom name for Custom
  final bool isCustom;
  const MarkTag._(this.tag, this.isCustom);

  static const bold = MarkTag._('bold', false);
  static const italic = MarkTag._('italic', false);
  static const underline = MarkTag._('underline', false);
  static const strike = MarkTag._('strike', false);
  static const code = MarkTag._('code', false);
  static const link = MarkTag._('link', false);
  factory MarkTag.custom(String name) => MarkTag._(name, true);

  dynamic toJson() => isCustom ? {'type': 'custom', 'name': tag} : tag;
}

/// A block type. Mirrors `rich_doc_core::schema::BlockType`.
class BlockType {
  final String value; // one of the fixed variants, or an arbitrary custom string
  const BlockType._(this.value);

  static const doc = BlockType._('doc');
  static const paragraph = BlockType._('paragraph');
  static const heading = BlockType._('heading');
  static const bulletList = BlockType._('bullet_list');
  static const orderedList = BlockType._('ordered_list');
  static const listItem = BlockType._('list_item');
  static const codeBlock = BlockType._('code_block');
  static const blockquote = BlockType._('blockquote');
  static const image = BlockType._('image');
  static const horizontalRule = BlockType._('horizontal_rule');
  static const table = BlockType._('table');
  static const tableRow = BlockType._('table_row');
  static const tableCell = BlockType._('table_cell');
  factory BlockType.custom(String name) => BlockType._(name);

  static const _fixed = {
    'doc', 'paragraph', 'heading', 'bullet_list', 'ordered_list', 'list_item',
    'code_block', 'blockquote', 'image', 'horizontal_rule', 'table', 'table_row', 'table_cell',
  };

  factory BlockType.fromJson(dynamic json) {
    if (json is String) return BlockType._(json);
    if (json is Map && json.containsKey('custom')) return BlockType._(json['custom'] as String);
    throw FormatException('unrecognized block_type json: $json');
  }

  dynamic toJson() => _fixed.contains(value) ? value : {'custom': value};

  @override
  bool operator ==(Object other) => other is BlockType && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

/// A not-yet-created node, for `InsertNode` / `DeleteNode`'s inverse.
/// Mirrors `rich_doc_core::transaction::NewNodeSpec`.
sealed class NewNodeSpec {
  Map<String, dynamic> toJson();

  factory NewNodeSpec.text(String text, {List<Mark> marks = const []}) = _TextSpec;
  factory NewNodeSpec.block(BlockType type, {Map<String, dynamic> attrs = const {}, List<NewNodeSpec> children = const []}) = _BlockSpec;

  /// Convenience matching `NewNodeSpec::paragraph` on the Rust side.
  static NewNodeSpec paragraph(String text) => NewNodeSpec.block(BlockType.paragraph, children: [NewNodeSpec.text(text)]);
}

class _TextSpec implements NewNodeSpec {
  final String text;
  final List<Mark> marks;
  _TextSpec(this.text, {this.marks = const []});
  @override
  Map<String, dynamic> toJson() => {'kind': 'Text', 'text': text, 'marks': marks.map((m) => m.toJson()).toList()};
}

class _BlockSpec implements NewNodeSpec {
  final BlockType nodeType;
  final Map<String, dynamic> attrs;
  final List<NewNodeSpec> children;
  _BlockSpec(this.nodeType, {this.attrs = const {}, this.children = const []});
  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Block',
        'node_type': nodeType.toJson(),
        'attrs': attrs,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// A primitive `Op`. One-to-one with `rich_doc_core::transaction::Op`.
sealed class Op {
  Map<String, dynamic> toJson();
}

class InsertTextOp implements Op {
  final NodeId node;
  final int offset;
  final String text;
  InsertTextOp({required this.node, required this.offset, required this.text});
  @override
  Map<String, dynamic> toJson() => {'op': 'insert_text', 'node': node.toJson(), 'offset': offset, 'text': text};
}

class DeleteTextOp implements Op {
  final NodeId node;
  final int start;
  final int end;
  DeleteTextOp({required this.node, required this.start, required this.end});
  @override
  Map<String, dynamic> toJson() => {'op': 'delete_text', 'node': node.toJson(), 'start': start, 'end': end};
}

class SplitBlockOp implements Op {
  final NodeId node;
  final int offset;
  SplitBlockOp({required this.node, required this.offset});
  @override
  Map<String, dynamic> toJson() => {'op': 'split_block', 'node': node.toJson(), 'offset': offset};
}

class MergeBlocksOp implements Op {
  final NodeId first;
  final NodeId second;
  MergeBlocksOp({required this.first, required this.second});
  @override
  Map<String, dynamic> toJson() => {'op': 'merge_blocks', 'first': first.toJson(), 'second': second.toJson()};
}

class SetAttrOp implements Op {
  final NodeId node;
  final String key;
  final dynamic value;
  SetAttrOp({required this.node, required this.key, required this.value});
  @override
  Map<String, dynamic> toJson() => {'op': 'set_attr', 'node': node.toJson(), 'key': key, 'value': value};
}

class InsertNodeOp implements Op {
  final NodeId parent;
  final int index;
  final NewNodeSpec node;
  InsertNodeOp({required this.parent, required this.index, required this.node});
  @override
  Map<String, dynamic> toJson() => {'op': 'insert_node', 'parent': parent.toJson(), 'index': index, 'node': node.toJson()};
}

class DeleteNodeOp implements Op {
  final NodeId node;
  DeleteNodeOp({required this.node});
  @override
  Map<String, dynamic> toJson() => {'op': 'delete_node', 'node': node.toJson()};
}

/// A `Command`: either a raw `Op` or a convenience composite. Mirrors
/// `rich_doc_core::commands::Command`.
sealed class Command {
  Map<String, dynamic> toJson();

  factory Command.op(Op op) = _OpCommand;
  factory Command.addMarkRange({required NodeId node, required int start, required int end, required Mark mark}) = _AddMarkRangeCommand;
  factory Command.removeMarkRange({required NodeId node, required int start, required int end, required MarkTag mark}) = _RemoveMarkRangeCommand;
}

class _OpCommand implements Command {
  final Op op;
  _OpCommand(this.op);
  @override
  Map<String, dynamic> toJson() => {'command': 'op', 'payload': op.toJson()};
}

class _AddMarkRangeCommand implements Command {
  final NodeId node;
  final int start;
  final int end;
  final Mark mark;
  _AddMarkRangeCommand({required this.node, required this.start, required this.end, required this.mark});
  @override
  Map<String, dynamic> toJson() =>
      {'command': 'add_mark_range', 'node': node.toJson(), 'start': start, 'end': end, 'mark': mark.toJson()};
}

class _RemoveMarkRangeCommand implements Command {
  final NodeId node;
  final int start;
  final int end;
  final MarkTag mark;
  _RemoveMarkRangeCommand({required this.node, required this.start, required this.end, required this.mark});
  @override
  Map<String, dynamic> toJson() =>
      {'command': 'remove_mark_range', 'node': node.toJson(), 'start': start, 'end': end, 'mark': mark.toJson()};
}

/// A batch of commands, exactly what `apply_command`'s `command_json`
/// argument expects.
class CommandBatch {
  final List<Command> ops;
  final String? reason;
  const CommandBatch(this.ops, {this.reason});

  String toJsonString() {
    final map = {
      'ops': ops.map((c) => c.toJson()).toList(),
      if (reason != null) 'reason': reason,
    };
    return jsonEncode(map);
  }
}
