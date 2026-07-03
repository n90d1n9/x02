//! Flutter/Dart-facing bridge crate.
//!
//! This crate is intentionally thin: `rich_doc_core` holds every bit of
//! actual document logic (schema, tree, ops, validation) and has zero
//! knowledge that Flutter or Dart exist, so it can be reused unmodified
//! as a wasm build for web, a CLI tool, or a server-side validator. This
//! crate's only job is exposing that logic across the FFI boundary.
//!
//! `api/document.rs` is the real API surface — see it for the actual
//! functions. This file just wires up flutter_rust_bridge's generated
//! glue.
//!
//! ---
//! ## One-time setup this crate still needs (requires the Flutter SDK,
//! ## which isn't available in the environment this was authored in):
//!
//! ```bash
//! cargo install flutter_rust_bridge_codegen
//! flutter_rust_bridge_codegen generate
//! ```
//!
//! That reads `src/api/**/*.rs`, generates `src/frb_generated.rs` (the
//! actual `extern "C"` boundary + type marshaling) and the matching
//! Dart bindings under the Flutter package's `lib/src/rust/`. Re-run it
//! any time a function signature in `api/` changes — which, by design,
//! should be rare, since the JSON boundary absorbs schema changes
//! without touching function signatures at all.

pub mod api;

#[cfg(test)]
mod tests;

#[cfg(not(test))]
mod frb_generated {
    // Placeholder: `flutter_rust_bridge_codegen generate` overwrites
    // this file with the real generated glue (`RustLib::init()`, the
    // wire-format structs, etc). Left as a stub here since codegen
    // requires the Flutter SDK toolchain to run.
}
