# rich_doc

A from-scratch rich-text document engine: a Rust core owning schema,
tree, edits, undo/redo, and validation; a thin FFI boundary; and a
Flutter package for rendering/editing. Built to replace `flutter_quill`
where the actual requirement was **schema control**, not Quill's Delta
format or its editing internals.

## Workspace layout

```
rich_doc/
  core/     rich_doc_core   — pure Rust. No FFI, no Flutter. Schema,
                              tree, transactions, validation, agent API.
                              Compiles to native and wasm32 unchanged.
  ffi/      rich_doc_ffi    — the Flutter/Dart-facing boundary. Six
                              functions, all handle+JSON. Depends on
                              rich_doc_core, knows nothing about Flutter
                              internals beyond "produce JSON strings".
  flutter_rich_doc/         — Dart package: model / state / rendering /
                              editing, each layer only depending on the
                              one below it.
```

## Why this shape (the actual design decisions)

**Tree schema, not Quill's Delta.** `Op`/`Delta` in Quill is optimized
for OT-style diffing. A node tree (`Tree` in `core/src/tree.rs`) with a
real content model (`core/src/content_model.rs`) is what lets you define
actual block types — tables, custom callouts, whatever your backend
needs — with validated nesting, instead of fighting a flat op log.

**Every edit is an invertible `Op`.** `transaction::apply_op` returns
the ops needed to undo itself. Undo/redo is "apply the inverse" — there
is no separate undo code path to keep in sync with the edit code path.

**Primitives vs. composites, in separate files.** `transaction.rs`
defines a small, stable `Op` vocabulary meant to be a long-term wire
format. `commands.rs` builds convenience operations (e.g.
`AddMarkRange`, which needs to split text and doesn't know node ids
until it does) *on top of* those primitives, in its own module. Adding
a new composite never touches the kernel.

**Content-model validation lives in its own module.** `content_model.rs`
is the single source of truth for "can X contain Y" and is checked
before any mutation, not after — an agent (or a bug) cannot construct
a `table_row` directly under `doc`, for example. Loosening or tightening
these rules never touches `tree.rs` or `transaction.rs`.

**The FFI boundary is handle + JSON, not a 1:1 type mirror.** This is
the actual future-proofing move: if `rich_doc_ffi` mirrored every `Op`
variant and block type as its own Dart-bound type, every schema change
would require re-running codegen and touching the Dart side. Instead
there are six functions (`create_document`, `load_document`,
`close_document`, `get_snapshot`, `get_portable_snapshot`,
`apply_command`) that never change shape. `describe_schema()` lets the
Dart/agent side discover current capabilities at runtime.

**Agent and human edits share one entry point.** `agent::execute_command_json`
is what both `rich_doc_ffi::apply_command` (called from Flutter) and an
LLM tool call run through. There's no separate, drift-prone "AI editing
API" — an agent can only do what the schema and validation already
allow a human to do, and a user can undo something an agent just did
because it produced the same kind of inverse ops.

**Dart-side layering mirrors the Rust side.** `model/` only knows the
JSON wire shape. `state/` (`DocumentController`, a Riverpod `Notifier`)
is the only thing that calls across FFI, and owns undo/redo. `rendering/`
is a pure function of a `DocumentTree` — no FFI calls, no mutation.
`editing/` is the one place that touches Flutter's actual text-input
APIs and turns them into `Command`s. Swapping any one of these later
(e.g. replacing the interim `TextField`-per-node editor with a real
`TextInputClient`) never requires touching the others.

## Building

```bash
# Core + FFI (pure Rust, works anywhere with cargo):
cd core && cargo test
cd ../ffi && cargo test

# Dart bindings (requires the Flutter SDK — not available in the
# environment this was authored in, so this step hasn't been run here):
cd ffi
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen generate   # reads flutter_rust_bridge.yaml

# Then in flutter_rich_doc/:
flutter pub get
```

## Known gaps / natural next steps

- `undo()`/`redo()` are implemented and tested at the state-layer logic
  level, but the Dart package hasn't been run through `flutter analyze`
  or a real Flutter app (no Flutter SDK in this environment) — review
  `state/document_controller.dart` once you can build it.
- `editing/text_editor.dart` is an honestly-scoped interim: one
  `TextField` per text node. Multi-run inline selection (bold spanning
  a selection that crosses node boundaries) needs a custom
  `TextInputClient`, which is real, substantial work — see that file's
  doc comment.
- `content_model.rs`'s rules for `TableCell` (text/paragraph only) and
  `Custom` (unrestricted) are reasonable defaults, not fixed — tighten
  or loosen per your backend's actual needs.
- wasm32 target: attempted `cargo build --target wasm32-unknown-unknown -p
  rich_doc_core` here and it failed — this sandbox's apt-installed Rust
  toolchain doesn't have the wasm32 standard library installed (only
  the target triple is known to rustc, not its sysroot). `rich_doc_core`
  itself has no platform-specific code or non-wasm-compatible
  dependencies (`serde`, `serde_json`, `thiserror` all support wasm32),
  so this should build cleanly with a proper `rustup target add
  wasm32-unknown-unknown` — just hasn't been verified in this
  environment. Verify it before relying on it.
