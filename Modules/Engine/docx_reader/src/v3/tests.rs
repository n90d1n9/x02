use crate::agent::{describe_schema, execute_command_json};
use crate::schema::{AttrValue, BlockType, Mark};
use crate::transaction::{apply_op, apply_transaction, NewNodeSpec, Op};
use crate::tree::{NodeId, NodeKind, Tree};

fn first_text_node(tree: &Tree) -> NodeId {
    // doc(0) -> paragraph(1) -> text(2) in a fresh tree
    let para = tree.children_of(tree.root).unwrap()[0];
    tree.children_of(para).unwrap()[0]
}

#[test]
fn insert_and_delete_text_roundtrip() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);

    let outcome = apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "Hello".into() }).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "Hello"),
        _ => panic!("expected text node"),
    }

    // undo via inverse
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, ""),
        _ => panic!("expected text node"),
    }
}

#[test]
fn delete_text_inverse_restores_content() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "Hello world".into() }).unwrap();

    let outcome = apply_op(&mut tree, &Op::DeleteText { node: text_node, start: 5, end: 11 }).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "Hello"),
        _ => panic!(),
    }
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "Hello world"),
        _ => panic!(),
    }
}

#[test]
fn split_and_merge_block_roundtrip() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "Hello world".into() }).unwrap();

    // Split at offset 5 -> "Hello" | " world" as two paragraphs.
    let outcome = apply_op(&mut tree, &Op::SplitBlock { node: text_node, offset: 5 }).unwrap();
    let doc_children = tree.children_of(tree.root).unwrap().to_vec();
    assert_eq!(doc_children.len(), 2, "should now have two paragraphs");

    let first_block = doc_children[0];
    let second_block = doc_children[1];
    let first_text_id = tree.children_of(first_block).unwrap()[0];
    let second_text_id = tree.children_of(second_block).unwrap()[0];
    match &tree.get(first_text_id).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "Hello"),
        _ => panic!(),
    }
    match &tree.get(second_text_id).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, " world"),
        _ => panic!(),
    }

    // Undo (merge back). merge_blocks reunites the two blocks but does
    // not coalesce adjacent text runs, so we now expect one paragraph
    // with two text-node children whose contents concatenate back to
    // the original string.
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    let doc_children_after = tree.children_of(tree.root).unwrap().to_vec();
    assert_eq!(doc_children_after.len(), 1, "should be merged back into one paragraph");
    let merged_children = tree.children_of(doc_children_after[0]).unwrap().to_vec();
    let concatenated: String = merged_children
        .iter()
        .map(|id| match &tree.get(*id).unwrap().kind {
            NodeKind::Text { text, .. } => text.clone(),
            _ => panic!("expected text node"),
        })
        .collect();
    assert_eq!(concatenated, "Hello world");
}

#[test]
fn add_and_remove_mark() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "bold me".into() }).unwrap();

    let outcome = apply_op(&mut tree, &Op::AddMark { node: text_node, mark: Mark::Bold }).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { marks, .. } => assert!(marks.iter().any(|m| matches!(m, Mark::Bold))),
        _ => panic!(),
    }
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { marks, .. } => assert!(marks.is_empty()),
        _ => panic!(),
    }
}

#[test]
fn insert_and_delete_node_roundtrip() {
    let mut tree = Tree::new_empty();
    let root = tree.root;
    let outcome = apply_op(
        &mut tree,
        &Op::InsertNode { parent: root, index: 1, node: NewNodeSpec::paragraph("second paragraph") },
    )
    .unwrap();
    assert_eq!(tree.children_of(tree.root).unwrap().len(), 2);
    let new_block = outcome.created[0];

    let del_outcome = apply_op(&mut tree, &Op::DeleteNode { node: new_block }).unwrap();
    assert_eq!(tree.children_of(tree.root).unwrap().len(), 1);

    // Undo the delete -> content comes back intact.
    apply_transaction(&mut tree, &del_outcome.inverse).unwrap();
    assert_eq!(tree.children_of(tree.root).unwrap().len(), 2);
    let restored_block = tree.children_of(tree.root).unwrap()[1];
    let restored_text = tree.children_of(restored_block).unwrap()[0];
    match &tree.get(restored_text).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "second paragraph"),
        _ => panic!(),
    }
}

#[test]
fn set_attr_roundtrip_including_clear() {
    let mut tree = Tree::new_empty();
    let para = tree.children_of(tree.root).unwrap()[0];

    // First set: no previous value -> inverse should be ClearAttr.
    let outcome = apply_op(&mut tree, &Op::SetAttr { node: para, key: "level".into(), value: AttrValue::Number(2.0) }).unwrap();
    match &tree.get(para).unwrap().kind {
        NodeKind::Block { attrs, .. } => assert_eq!(attrs.get("level"), Some(&AttrValue::Number(2.0))),
        _ => panic!(),
    }
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    match &tree.get(para).unwrap().kind {
        NodeKind::Block { attrs, .. } => assert!(!attrs.contains_key("level")),
        _ => panic!(),
    }
}

#[test]
fn schema_validation_rejects_wrong_node_kind() {
    let mut tree = Tree::new_empty();
    let para = tree.children_of(tree.root).unwrap()[0];
    // Trying to insert text at a block node should fail cleanly.
    let err = apply_op(&mut tree, &Op::InsertText { node: para, offset: 0, text: "x".into() }).unwrap_err();
    assert!(matches!(err, crate::tree::DocError::NotText(_)));
}

#[test]
fn agent_json_command_end_to_end() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);

    let node_json = serde_json::to_string(&text_node).unwrap();
    let cmd = format!(
        r#"{{"ops": [{{"command": "op", "payload": {{"op": "insert_text", "node": {node_json}, "offset": 0, "text": "hi from an agent"}}}}], "reason": "demo"}}"#
    );
    let result = execute_command_json(&mut tree, &cmd);
    assert!(result.ok, "agent command should succeed: {:?}", result.error);
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "hi from an agent"),
        _ => panic!(),
    }
}

#[test]
fn agent_command_batch_rolls_back_on_failure() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    let bogus = NodeId(9999);

    let node_json = serde_json::to_string(&text_node).unwrap();
    let bogus_json = serde_json::to_string(&bogus).unwrap();
    let cmd = format!(
        r#"{{"ops": [
            {{"command": "op", "payload": {{"op": "insert_text", "node": {node_json}, "offset": 0, "text": "should be rolled back"}}}},
            {{"command": "op", "payload": {{"op": "insert_text", "node": {bogus_json}, "offset": 0, "text": "boom"}}}}
        ]}}"#
    );
    let result = execute_command_json(&mut tree, &cmd);
    assert!(!result.ok);
    match &tree.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "", "first op should have been rolled back"),
        _ => panic!(),
    }
}

#[test]
fn schema_description_is_valid_json() {
    let v = describe_schema();
    assert!(v.get("primitive_ops").is_some());
    assert!(v.get("composite_commands").is_some());
    assert!(v.get("block_types").is_some());
}

#[test]
fn tree_json_roundtrip() {
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "persist me".into() }).unwrap();

    let json = crate::serialize::to_json(&tree).unwrap();
    let restored = crate::serialize::from_json(&json).unwrap();
    match &restored.get(text_node).unwrap().kind {
        NodeKind::Text { text, .. } => assert_eq!(text, "persist me"),
        _ => panic!(),
    }
}

#[test]
fn block_type_custom_variant_round_trips_through_json() {
    let bt = BlockType::Custom("callout".into());
    let json = serde_json::to_string(&bt).unwrap();
    let back: BlockType = serde_json::from_str(&json).unwrap();
    assert_eq!(bt, back);
}

#[test]
fn schema_rejects_invalid_child_insertion() {
    let mut tree = Tree::new_empty();
    let root = tree.root;
    // A table_row can't go directly under doc — it must be under a table.
    let bad = NewNodeSpec::Block { node_type: BlockType::TableRow, attrs: Default::default(), children: vec![] };
    let err = apply_op(&mut tree, &Op::InsertNode { parent: root, index: 0, node: bad }).unwrap_err();
    assert!(matches!(err, crate::tree::DocError::Schema(_)));
    // Document must be untouched.
    assert_eq!(tree.children_of(root).unwrap().len(), 1);
}

#[test]
fn schema_allows_nested_lists_under_list_item() {
    let mut tree = Tree::new_empty();
    let root = tree.root;
    let list = NewNodeSpec::Block {
        node_type: BlockType::BulletList,
        attrs: Default::default(),
        children: vec![NewNodeSpec::Block {
            node_type: BlockType::ListItem,
            attrs: Default::default(),
            children: vec![
                NewNodeSpec::Text { text: "outer item".into(), marks: vec![] },
                NewNodeSpec::Block {
                    node_type: BlockType::BulletList,
                    attrs: Default::default(),
                    children: vec![NewNodeSpec::Block {
                        node_type: BlockType::ListItem,
                        attrs: Default::default(),
                        children: vec![NewNodeSpec::Text { text: "nested item".into(), marks: vec![] }],
                    }],
                },
            ],
        }],
    };
    let outcome = apply_op(&mut tree, &Op::InsertNode { parent: root, index: 0, node: list }).unwrap();
    assert_eq!(outcome.created.len(), 1);
}

#[test]
fn add_mark_range_only_marks_the_selected_slice() {
    use crate::commands::{apply_command, Command};
    let mut tree = Tree::new_empty();
    let text_node = first_text_node(&tree);
    apply_op(&mut tree, &Op::InsertText { node: text_node, offset: 0, text: "Hello world".into() }).unwrap();

    // Bold just "world" (chars 6..11).
    let outcome = apply_command(
        &mut tree,
        &Command::AddMarkRange { node: text_node, start: 6, end: 11, mark: Mark::Bold },
    )
    .unwrap();

    let para = tree.children_of(tree.root).unwrap()[0];
    let children = tree.children_of(para).unwrap().to_vec();
    assert_eq!(children.len(), 2, "expected the run split into 'Hello ' and 'world'");
    let texts: Vec<(String, bool)> = children
        .iter()
        .map(|id| match &tree.get(*id).unwrap().kind {
            NodeKind::Text { text, marks } => (text.clone(), marks.iter().any(|m| matches!(m, Mark::Bold))),
            _ => panic!(),
        })
        .collect();
    assert_eq!(texts[0], ("Hello ".to_string(), false));
    assert_eq!(texts[1], ("world".to_string(), true));

    // Undo should restore a single unmarked "Hello world" text node.
    apply_transaction(&mut tree, &outcome.inverse).unwrap();
    let para_children_after = tree.children_of(para).unwrap().to_vec();
    assert_eq!(para_children_after.len(), 1);
    match &tree.get(para_children_after[0]).unwrap().kind {
        NodeKind::Text { text, marks } => {
            assert_eq!(text, "Hello world");
            assert!(marks.is_empty());
        }
        _ => panic!(),
    }
}
