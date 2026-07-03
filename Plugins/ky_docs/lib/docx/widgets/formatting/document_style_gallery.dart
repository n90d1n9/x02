import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'document_style_preset.dart';

/// Shows quick paragraph style presets inside the document formatting ribbon.
class DocumentStyleGallery extends StatefulWidget {
  static const galleryKey = ValueKey('document-style-gallery');
  static const presetPrefixKey = 'document-style-preset';

  final quill.QuillController controller;
  final List<DocumentStylePreset> presets;
  final DocumentStylePresetApplier applier;

  const DocumentStyleGallery({
    super.key,
    required this.controller,
    this.presets = DocumentStylePresetCatalog.presets,
    this.applier = const DocumentStylePresetApplier(),
  });

  @override
  State<DocumentStyleGallery> createState() => _DocumentStyleGalleryState();
}

/// Keeps the visible gallery selection in sync with the Quill controller.
class _DocumentStyleGalleryState extends State<DocumentStyleGallery> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(DocumentStyleGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = widget.applier.activePreset(
      controller: widget.controller,
      presets: widget.presets,
    );

    return SizedBox(
      key: DocumentStyleGallery.galleryKey,
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final preset = widget.presets[index];
          return _StylePresetCard(
            key: Key(
              '${DocumentStyleGallery.presetPrefixKey}-${preset.id.name}',
            ),
            preset: preset,
            active: activePreset.id == preset.id,
            onTap: () {
              widget.applier.apply(
                controller: widget.controller,
                preset: preset,
              );
            },
          );
        },
      ),
    );
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}

/// Renders one selectable style preset card in the horizontal gallery.
class _StylePresetCard extends StatelessWidget {
  final DocumentStylePreset preset;
  final bool active;
  final VoidCallback onTap;

  const _StylePresetCard({
    super.key,
    required this.preset,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '${preset.label}: ${preset.description}',
      child: SizedBox(
        width: 126,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.primaryContainer.withValues(alpha: 0.72)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active
                      ? colorScheme.primary.withValues(alpha: 0.32)
                      : colorScheme.outlineVariant.withValues(alpha: 0.56),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    _StyleSample(preset: preset, active: active),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: active
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: active
                                      ? colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.78)
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the sample glyph shown in each style preset card.
class _StyleSample extends StatelessWidget {
  final DocumentStylePreset preset;
  final bool active;

  const _StyleSample({required this.preset, required this.active});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        preset.sampleText,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: active
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
