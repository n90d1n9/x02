import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'page_orientation.dart';
import 'page_size.dart';

/// Stores print layout settings shared by the editor, preview, and exporters.
class PageSettings {
  final PageSize pageSize;
  final DocumentPageOrientation orientation;
  final EdgeInsets margins;
  final bool showPageNumbers;
  final String pageNumberFormat;
  final int pageNumberStart;
  final String? header;
  final String? footer;
  final bool showHeader;
  final bool showFooter;
  const PageSettings({
    this.pageSize = PageSize.a4,
    this.orientation = DocumentPageOrientation.portrait,
    this.margins = const EdgeInsets.all(72),
    this.showPageNumbers = true,
    this.pageNumberFormat = 'Page {n}',
    this.pageNumberStart = 1,
    this.header,
    this.footer,
    this.showHeader = false,
    this.showFooter = false,
  });
  PageSettings copyWith({
    PageSize? pageSize,
    DocumentPageOrientation? orientation,
    EdgeInsets? margins,
    bool? showPageNumbers,
    String? pageNumberFormat,
    int? pageNumberStart,
    String? header,
    String? footer,
    bool? showHeader,
    bool? showFooter,
  }) {
    return PageSettings(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      margins: margins ?? this.margins,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      pageNumberFormat: pageNumberFormat ?? this.pageNumberFormat,
      pageNumberStart: pageNumberStart ?? this.pageNumberStart,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      showHeader: showHeader ?? this.showHeader,
      showFooter: showFooter ?? this.showFooter,
    );
  }

  Size getPageSize() {
    final portraitSize = switch (pageSize) {
      PageSize.a4 => const Size(595, 842),
      PageSize.letter => const Size(612, 792),
      PageSize.legal => const Size(612, 1008),
    };

    return switch (orientation) {
      DocumentPageOrientation.portrait => portraitSize,
      DocumentPageOrientation.landscape => Size(
        portraitSize.height,
        portraitSize.width,
      ),
    };
  }

  double getContentHeight() {
    final size = getPageSize();
    return size.height - margins.top - margins.bottom;
  }
}
