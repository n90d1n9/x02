/// Pure rendering: `DocumentTree` in, widgets out. This layer never
/// calls into Rust and never mutates anything — it's a straightforward
/// recursive walk keyed on `BlockType`. Add a new block type in
/// `content_model.rs` + a `case` here and it renders; nothing else in
/// this package needs to change.
library rich_doc_view;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editing/text_editor.dart';
import '../model/commands.dart';
import '../model/document_tree.dart';
import '../state/document_controller.dart';

class DocumentView extends ConsumerWidget {
  const DocumentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentControllerProvider);
    final tree = state.tree;
    final root = tree[tree.root] as BlockNode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final childId in root.children) NodeView(tree: tree, nodeId: childId)],
    );
  }
}

/// Renders one node (and, for blocks, its subtree) from a
/// [DocumentTree]. Stateless and side-effect-free by construction: it
/// only reads `tree`, it never reaches into `documentControllerProvider`
/// itself — editing widgets like [TextNodeEditor] are the only leaves
/// that do that, keeping "what things look like" and "how edits happen"
/// in genuinely separate call paths.
class NodeView extends StatelessWidget {
  final DocumentTree tree;
  final NodeId nodeId;
  const NodeView({super.key, required this.tree, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    final node = tree[nodeId]!;
    if (node is TextNode) {
      return TextNodeEditor(node: node);
    }
    final block = node as BlockNode;
    final children = [for (final c in block.children) NodeView(tree: tree, nodeId: c)];

    if (block.nodeType == BlockType.paragraph) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children));
    }
    if (block.nodeType == BlockType.heading) {
      final level = (block.attrs['level'] as num?)?.toInt() ?? 1;
      final style = switch (level) {
        1 => Theme.of(context).textTheme.headlineMedium,
        2 => Theme.of(context).textTheme.headlineSmall,
        _ => Theme.of(context).textTheme.titleLarge,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DefaultTextStyle.merge(style: style, child: Column(children: children)),
      );
    }
    if (block.nodeType == BlockType.bulletList || block.nodeType == BlockType.orderedList) {
      final ordered = block.nodeType == BlockType.orderedList;
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < block.children.length; i++)
              _ListItemRow(
                marker: ordered ? '${i + 1}.' : '\u2022',
                child: NodeView(tree: tree, nodeId: block.children[i]),
              ),
          ],
        ),
      );
    }
    if (block.nodeType == BlockType.blockquote) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.grey))),
        child: Column(children: children),
      );
    }
    if (block.nodeType == BlockType.codeBlock) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        color: const Color(0x11000000),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'monospace'),
          child: Column(children: children),
        ),
      );
    }
    if (block.nodeType == BlockType.horizontalRule) {
      return const Divider();
    }
    if (block.nodeType == BlockType.image) {
      final src = block.attrs['src'] as String?;
      return src == null ? const SizedBox.shrink() : Image.network(src);
    }
    if (block.nodeType == BlockType.listItem) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    if (block.nodeType == BlockType.table) {
      return Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        children: [for (final rowId in block.children) _tableRow(tree, rowId)],
      );
    }

    // Unknown/custom block types: render children plainly rather than
    // dropping content silently. Apps registering their own Custom
    // block types (callouts, embeds, ...) should add a case above this
    // fallback — see the module doc comment.
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  TableRow _tableRow(DocumentTree tree, NodeId rowId) {
    final row = tree[rowId] as BlockNode;
    return TableRow(
      children: [
        for (final cellId in row.children)
          Padding(padding: const EdgeInsets.all(4), child: NodeView(tree: tree, nodeId: cellId)),
      ],
    );
  }
}

class _ListItemRow extends StatelessWidget {
  final String marker;
  final Widget child;
  const _ListItemRow({required this.marker, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 20, child: Text(marker)),
        Expanded(child: child),
      ],
    );
  }
}
