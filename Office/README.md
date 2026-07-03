# Kaysir Office

Kaysir Office is the shared family workspace for document, spreadsheet, and
presentation products.

## Dart Products

- `ky_docs` owns document editing surfaces and DOCX/PDF-oriented flows.
- `ky_sheet` owns spreadsheet editing surfaces and sheet-engine integration.
- `ky_slide` owns presentation editing surfaces and slide-engine integration.
- `ky_office_core` owns reusable Office-family models that can be shared by
  product shells, launchers, menus, recent-file surfaces, and
  capability-aware navigation.
- `ky_office` owns reusable Flutter UI primitives that render
  `ky_office_core` models, including product cards, recent-file cards, home
  surfaces, and family shells.

Product packages should expose their own editor screens, state, and services.
Shared code belongs in `ky_office_core` only when it is product-neutral and does
not depend on editor internals. Shared Flutter widgets belong in `ky_office`
when they are product-neutral but need Material UI.

## Native/Core Workspace

The Rust workspace keeps reusable document, spreadsheet, slide, PDF, graphics,
and file-format engines separate from Flutter product packages. Product packages
should talk to native engines through focused services or bridges rather than
importing broad native concerns into UI code.

## Boundaries

- Keep product-specific models inside the product package.
- Keep shared identity, capability, routing metadata, and small cross-product
  primitives in `ky_office_core`.
- Keep shared Material widgets and visual tokens in `ky_office`.
- Avoid central files that need to know every editor detail.
- Prefer adding narrow shared types first, then migrate duplicated product code
  only when two or more products genuinely need the same behavior.
