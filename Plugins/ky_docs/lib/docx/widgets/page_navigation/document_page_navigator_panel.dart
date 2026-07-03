import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/document_navigation_panel_switcher.dart';
import '../navigation/document_navigation_rail_header.dart';
import 'document_page_navigation_model.dart';

/// Shows selectable page thumbnails and document map entry points.
class DocumentPageNavigatorPanel extends StatefulWidget {
  static const panelKey = Key('document-page-navigator-panel');
  static const outlineButtonKey = Key('document-page-navigator-outline-button');
  static const pageListKey = Key('document-page-navigator-list');
  static const pageJumpFieldKey = Key('document-page-navigator-jump-field');
  static const pageJumpButtonKey = Key('document-page-navigator-jump-button');
  static const pageJumpErrorKey = Key('document-page-navigator-jump-error');
  static const closeButtonKey = Key('document-page-navigator-close-button');
  static const firstPageButtonKey = Key('document-page-navigator-first-page');
  static const previousPageButtonKey = Key(
    'document-page-navigator-previous-page',
  );
  static const nextPageButtonKey = Key('document-page-navigator-next-page');
  static const lastPageButtonKey = Key('document-page-navigator-last-page');

  final DocumentPageNavigationModel model;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onOpenOutline;
  final VoidCallback? onClose;

  const DocumentPageNavigatorPanel({
    super.key,
    required this.model,
    required this.onPageSelected,
    this.onOpenOutline,
    this.onClose,
  });

  static Key pageTileKey(int pageNumber) {
    return Key('document-page-navigator-page-$pageNumber');
  }

  @override
  State<DocumentPageNavigatorPanel> createState() =>
      _DocumentPageNavigatorPanelState();
}

class _DocumentPageNavigatorPanelState
    extends State<DocumentPageNavigatorPanel> {
  static const _pageTileExtent = 212.0;

  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: widget.model.selectedPageScrollOffset(
      pageTileExtent: _pageTileExtent,
    ),
  );

  @override
  void initState() {
    super.initState();
    _scheduleSelectedPageScroll();
  }

  @override
  void didUpdateWidget(covariant DocumentPageNavigatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.selectedPage != widget.model.selectedPage ||
        oldWidget.model.pageCount != widget.model.pageCount) {
      _scheduleSelectedPageScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: DocumentPageNavigatorPanel.panelKey,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.62),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentNavigationRailHeader(
            icon: Icons.view_agenda_outlined,
            title: 'Pages',
            subtitle: widget.model.formatLabel,
            countLabel: widget.model.countLabel,
            badgeTone: DocumentNavigationRailBadgeTone.secondary,
            closeButtonKey: DocumentPageNavigatorPanel.closeButtonKey,
            onClose: widget.onClose,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DocumentNavigationPanelSwitcher(
              selectedMode: DocumentNavigationPanelMode.pages,
              onOutlineSelected: widget.onOpenOutline,
              outlineButtonKey: DocumentPageNavigatorPanel.outlineButtonKey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _PageStepControl(
              model: widget.model,
              onPageSelected: widget.onPageSelected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PageJumpControl(
              model: widget.model,
              onPageSelected: widget.onPageSelected,
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                key: DocumentPageNavigatorPanel.pageListKey,
                controller: _scrollController,
                itemExtent: _pageTileExtent,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                itemCount: widget.model.pageCount,
                itemBuilder: (context, index) {
                  final item = widget.model.itemForPage(index + 1);
                  return _PageNavigatorTile(
                    key: DocumentPageNavigatorPanel.pageTileKey(
                      item.pageNumber,
                    ),
                    item: item,
                    onTap: () => widget.onPageSelected(item.pageNumber),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleSelectedPageScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedPageIntoView();
    });
  }

  void _scrollSelectedPageIntoView() {
    if (!mounted || !_scrollController.hasClients) return;

    final targetOffset = widget.model.selectedPageScrollOffset(
      pageTileExtent: _pageTileExtent,
    );
    final clampedOffset = targetOffset
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    if ((_scrollController.offset - clampedOffset).abs() < 0.5) return;

    _scrollController.jumpTo(clampedOffset);
  }
}

/// Provides previous and next page controls for the page navigator rail.
class _PageStepControl extends StatelessWidget {
  final DocumentPageNavigationModel model;
  final ValueChanged<int> onPageSelected;

  const _PageStepControl({required this.model, required this.onPageSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          _PageStepButton(
            key: DocumentPageNavigatorPanel.firstPageButtonKey,
            icon: Icons.first_page,
            tooltip: 'First page',
            enabled: model.canGoToFirstPage,
            onPressed: () => onPageSelected(model.firstPage),
          ),
          _PageStepButton(
            key: DocumentPageNavigatorPanel.previousPageButtonKey,
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            enabled: model.canGoToPreviousPage,
            onPressed: () => onPageSelected(model.previousPage),
          ),
          Expanded(
            child: Text(
              model.selectedPageLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _PageStepButton(
            key: DocumentPageNavigatorPanel.nextPageButtonKey,
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            enabled: model.canGoToNextPage,
            onPressed: () => onPageSelected(model.nextPage),
          ),
          _PageStepButton(
            key: DocumentPageNavigatorPanel.lastPageButtonKey,
            icon: Icons.last_page,
            tooltip: 'Last page',
            enabled: model.canGoToLastPage,
            onPressed: () => onPageSelected(model.lastPage),
          ),
        ],
      ),
    );
  }
}

/// Renders a compact icon button for moving through document pages.
class _PageStepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _PageStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onPressed : null,
    );
  }
}

class _PageJumpControl extends StatefulWidget {
  final DocumentPageNavigationModel model;
  final ValueChanged<int> onPageSelected;

  const _PageJumpControl({required this.model, required this.onPageSelected});

  @override
  State<_PageJumpControl> createState() => _PageJumpControlState();
}

class _PageJumpControlState extends State<_PageJumpControl> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void didUpdateWidget(covariant _PageJumpControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_errorText != null &&
        oldWidget.model.pageCount != widget.model.pageCount) {
      _errorText = _errorMessage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: DocumentPageNavigatorPanel.pageJumpFieldKey,
          controller: _controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Go to page',
            prefixIcon: const Icon(Icons.numbers, size: 18),
            suffixIcon: IconButton(
              key: DocumentPageNavigatorPanel.pageJumpButtonKey,
              tooltip: 'Go to page',
              icon: const Icon(Icons.arrow_forward, size: 18),
              onPressed: _submit,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 38,
            ),
            filled: true,
            fillColor: colorScheme.surface.withValues(alpha: 0.72),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText == null
                    ? colorScheme.outlineVariant.withValues(alpha: 0.72)
                    : colorScheme.error.withValues(alpha: 0.72),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorText == null
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _errorText == null
              ? const SizedBox.shrink()
              : Padding(
                  key: DocumentPageNavigatorPanel.pageJumpErrorKey,
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _submit() {
    final pageNumber = widget.model.pageForInput(_controller.text);
    if (pageNumber == null) {
      setState(() => _errorText = _errorMessage());
      return;
    }

    setState(() {
      _errorText = null;
      _controller.text = pageNumber.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
    widget.onPageSelected(pageNumber);
  }

  String _errorMessage() {
    return 'Enter ${widget.model.jumpRangeLabel}';
  }
}

class _PageNavigatorTile extends StatelessWidget {
  final DocumentPageNavigationItem item;
  final VoidCallback onTap;

  const _PageNavigatorTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primaryContainer.withValues(alpha: 0.48);
    final borderColor = item.selected
        ? colorScheme.primary.withValues(alpha: 0.55)
        : colorScheme.outlineVariant.withValues(alpha: 0.62);

    return Semantics(
      selected: item.selected,
      button: true,
      label: item.semanticLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: item.selected ? selectedColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                children: [
                  _PageThumbnail(item: item),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.pageLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: item.selected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: item.selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ),
                      if (item.selected)
                        _CurrentPageBadge(colorScheme: colorScheme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  static const _maxWidth = 106.0;
  static const _maxHeight = 136.0;

  final DocumentPageNavigationItem item;

  const _PageThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = item.pageSize.width / item.pageSize.height;
    var width = _maxWidth;
    var height = width / ratio;
    if (height > _maxHeight) {
      height = _maxHeight;
      width = height * ratio;
    }

    return SizedBox(
      height: _maxHeight,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: item.selected
                  ? colorScheme.primary.withValues(alpha: 0.52)
                  : colorScheme.outlineVariant.withValues(alpha: 0.78),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 12, 11, 10),
            child: _ThumbnailLines(selected: item.selected),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailLines extends StatelessWidget {
  final bool selected;

  const _ThumbnailLines({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = selected
        ? colorScheme.primary.withValues(alpha: 0.42)
        : colorScheme.secondary.withValues(alpha: 0.26);
    final lineColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThumbnailLine(widthFactor: 0.62, color: accentColor, height: 5),
        const SizedBox(height: 7),
        for (final widthFactor in const [0.92, 0.78, 0.64]) ...[
          _ThumbnailLine(widthFactor: widthFactor, color: lineColor),
          const SizedBox(height: 5),
        ],
        const Spacer(),
        _ThumbnailLine(widthFactor: 0.38, color: lineColor, height: 3),
      ],
    );
  }
}

class _ThumbnailLine extends StatelessWidget {
  final double widthFactor;
  final Color color;
  final double height;

  const _ThumbnailLine({
    required this.widthFactor,
    required this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _CurrentPageBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _CurrentPageBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Current',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
