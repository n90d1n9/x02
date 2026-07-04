/// A read-only Dart mirror of the Rust `Tree`, parsed from
/// `get_snapshot()`'s JSON. This is deliberately dumb: it has no edit
/// methods. All mutation happens in Rust via `Command`s (see
/// `commands.dart` and `document_controller.dart`); this class exists
/// only so the rendering layer has something to walk.
library rich_doc_tree;

import 'commands.dart' show NodeId, BlockType, Mark;

sealed class DocNode {
  final NodeId id;
  final NodeId? parent;
  const DocNode(this.id, this.parent);
}

class BlockNode extends DocNode {
  final BlockType nodeType;
  final Map<String, dynamic> attrs;
  final List<NodeId> children;
  const BlockNode(super.id, super.parent, this.nodeType, this.attrs, this.children);
}

class TextNode extends DocNode {
  final String text;
  final List<Mark> marks;
  const TextNode(super.id, super.parent, this.text, this.marks);
}

class DocumentTree {
  final Map<int, DocNode> _nodes;
  final NodeId root;

  const DocumentTree._(this._nodes, this.root);

  DocNode? operator [](NodeId id) => _nodes[id.value];

  List<DocNode> childrenOf(NodeId id) {
    final node = this[id];
    if (node is BlockNode) {
      return node.children.map((c) => this[c]!).toList();
    }
    return const [];
  }

  factory DocumentTree.fromJson(Map<String, dynamic> json) {
    final nodesJson = Map<String, dynamic>.from(json['nodes'] as Map);
    final nodes = <int, DocNode>{};
    for (final entry in nodesJson.entries) {
      final idInt = int.parse(entry.key);
      final nodeJson = Map<String, dynamic>.from(entry.value as Map);
      final id = NodeId(idInt);
      final parentJson = nodeJson['parent'];
      final parent = parentJson == null ? null : NodeId(parentJson as int);
      final kindJson = Map<String, dynamic>.from(nodeJson['kind'] as Map);

      if (kindJson['kind'] == 'Block') {
        nodes[idInt] = BlockNode(
          id,
          parent,
          BlockType.fromJson(kindJson['node_type']),
          Map<String, dynamic>.from(kindJson['attrs'] as Map? ?? {}),
          (kindJson['children'] as List).map((c) => NodeId(c as int)).toList(),
        );
      } else {
        nodes[idInt] = TextNode(
          id,
          parent,
          kindJson['text'] as String,
          (kindJson['marks'] as List).map((m) => Mark.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
        );
      }
    }
    return DocumentTree._(nodes, NodeId(json['root'] as int));
  }
}
