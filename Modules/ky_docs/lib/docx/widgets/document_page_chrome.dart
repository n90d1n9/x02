import 'package:flutter/material.dart';

import '../models/page_settings.dart';
import 'page_chrome/document_header_footer_quick_edit_dialog.dart';

/// Renders print-layout page chrome such as headers, footers, and page numbers.
class DocumentPageChrome extends StatelessWidget {
  static const headerKey = ValueKey('document-page-chrome-header');
  static const footerKey = ValueKey('document-page-chrome-footer');
  static const pageNumberKey = ValueKey('document-page-chrome-page-number');
  static const headerEditButtonKey = ValueKey(
    'document-page-chrome-header-edit',
  );
  static const footerEditButtonKey = ValueKey(
    'document-page-chrome-footer-edit',
  );

  final PageSettings pageSettings;
  final int currentPage;
  final ValueChanged<PageSettings>? onPageSettingsChanged;
  final Widget child;

  const DocumentPageChrome({
    super.key,
    required this.pageSettings,
    this.currentPage = 1,
    this.onPageSettingsChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final showHeader = pageSettings.showHeader;
    final showFooter = pageSettings.showFooter || pageSettings.showPageNumbers;
    if (!showHeader && !showFooter) return child;

    return Column(
      children: [
        if (showHeader)
          _PageChromeBand(
            key: headerKey,
            text: pageSettings.header,
            alignment: Alignment.centerLeft,
            fallback: 'Header',
            editButtonKey: headerEditButtonKey,
            onEdit: onPageSettingsChanged == null
                ? null
                : () => _editRegion(context, DocumentHeaderFooterRegion.header),
          ),
        Expanded(child: child),
        if (showFooter)
          _PageFooterBand(
            footerText: pageSettings.footer,
            pageNumber: pageSettings.showPageNumbers
                ? DocumentPageNumberFormatter.format(
                    pageSettings: pageSettings,
                    currentPage: currentPage,
                  )
                : null,
            onEdit: onPageSettingsChanged == null
                ? null
                : () => _editRegion(context, DocumentHeaderFooterRegion.footer),
          ),
      ],
    );
  }

  Future<void> _editRegion(
    BuildContext context,
    DocumentHeaderFooterRegion region,
  ) async {
    final updatedSettings = await DocumentHeaderFooterQuickEditDialog.show(
      context,
      region: region,
      pageSettings: pageSettings,
    );
    if (updatedSettings == null || !context.mounted) return;
    onPageSettingsChanged?.call(updatedSettings);
  }
}

/// Formats page number text using the current page settings.
class DocumentPageNumberFormatter {
  const DocumentPageNumberFormatter._();

  static String format({
    required PageSettings pageSettings,
    required int currentPage,
  }) {
    final pageNumber = pageSettings.pageNumberStart + currentPage - 1;
    final format = pageSettings.pageNumberFormat.trim().isEmpty
        ? 'Page {n}'
        : pageSettings.pageNumberFormat.trim();
    return format.replaceAll('{n}', pageNumber.toString());
  }
}

/// Displays one header or footer text band inside the print page surface.
class _PageChromeBand extends StatelessWidget {
  final String? text;
  final Alignment alignment;
  final String fallback;
  final Key editButtonKey;
  final VoidCallback? onEdit;

  const _PageChromeBand({
    super.key,
    required this.text,
    required this.alignment,
    required this.fallback,
    required this.editButtonKey,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveText = text?.trim().isNotEmpty == true
        ? text!.trim()
        : fallback;

    return Container(
      height: 32,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              effectiveText,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onEdit != null)
            _PageChromeEditButton(
              buttonKey: editButtonKey,
              tooltip: 'Edit $fallback',
              onPressed: onEdit!,
            ),
        ],
      ),
    );
  }
}

/// Displays footer text and generated page numbers in the print page surface.
class _PageFooterBand extends StatelessWidget {
  final String? footerText;
  final String? pageNumber;
  final VoidCallback? onEdit;

  const _PageFooterBand({
    required this.footerText,
    required this.pageNumber,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showFooterText = footerText?.trim().isNotEmpty == true;

    return Container(
      key: DocumentPageChrome.footerKey,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              showFooterText ? footerText!.trim() : '',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onEdit != null)
            _PageChromeEditButton(
              buttonKey: DocumentPageChrome.footerEditButtonKey,
              tooltip: 'Edit footer',
              onPressed: onEdit!,
            ),
          if (pageNumber != null)
            Text(
              key: DocumentPageChrome.pageNumberKey,
              pageNumber!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a compact edit affordance for page header and footer bands.
class _PageChromeEditButton extends StatelessWidget {
  final Key buttonKey;
  final String tooltip;
  final VoidCallback onPressed;

  const _PageChromeEditButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
