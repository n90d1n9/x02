import 'package:flutter/material.dart';

/// Defines the type of section break.
enum SectionBreakType {
  nextPage,      // Starts new section on next page
  continuous,    // Starts new section on same page (for columns)
  evenPage,      // Starts on next even-numbered page
  oddPage,       // Starts on next odd-numbered page
}

/// Represents page size configurations.
class PageSize {
  final String name;
  final double width; // In points (72 points = 1 inch)
  final double height;

  const PageSize({required this.name, required this.width, required this.height});

  static const PageSize A4 = PageSize(name: 'A4', width: 595.0, height: 842.0);
  static const PageSize Letter = PageSize(name: 'Letter', width: 612.0, height: 792.0);
  static const PageSize Legal = PageSize(name: 'Legal', width: 612.0, height: 1008.0);
  static const PageSize Tabloid = PageSize(name: 'Tabloid', width: 792.0, height: 1224.0);

  static List<PageSize> get presets => [A4, Letter, Legal, Tabloid];
}

/// Represents the margins for a section.
class SectionMargins {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final double header;
  final double footer;

  const SectionMargins({
    this.top = 72.0,
    this.bottom = 72.0,
    this.left = 72.0,
    this.right = 72.0,
    this.header = 36.0,
    this.footer = 36.0,
  });

  static const SectionMargins normal = SectionMargins(top: 96, bottom: 96, left: 96, right: 96);
  static const SectionMargins narrow = SectionMargins(top: 36, bottom: 36, left: 36, right: 36);
  static const SectionMargins moderate = SectionMargins(top: 72, bottom: 72, left: 72, right: 72);
  static const SectionMargins wide = SectionMargins(top: 144, bottom: 144, left: 144, right: 144);
}

/// Represents a single section within the document.
class SectionModel {
  final String id;
  final PageSize pageSize;
  final SectionMargins margins;
  final bool isLandscape;
  final int columnCount;
  final double columnSpacing;
  final SectionBreakType breakType;
  final bool differentFirstPage;
  final bool differentOddEven;
  final int pageNumberStart;
  final Color? backgroundColor;
  final String? watermarkText;

  SectionModel({
    required this.id,
    this.pageSize = PageSize.A4,
    this.margins = SectionMargins.normal,
    this.isLandscape = false,
    this.columnCount = 1,
    this.columnSpacing = 24.0,
    this.breakType = SectionBreakType.nextPage,
    this.differentFirstPage = false,
    this.differentOddEven = false,
    this.pageNumberStart = 1,
    this.backgroundColor,
    this.watermarkText,
  });

  double get effectiveWidth => isLandscape ? pageSize.height : pageSize.width;
  double get effectiveHeight => isLandscape ? pageSize.width : pageSize.height;

  double get contentWidth => effectiveWidth - margins.left - margins.right;
  double get contentHeight => effectiveHeight - margins.top - margins.bottom;

  SectionModel copyWith({
    String? id,
    PageSize? pageSize,
    SectionMargins? margins,
    bool? isLandscape,
    int? columnCount,
    double? columnSpacing,
    SectionBreakType? breakType,
    bool? differentFirstPage,
    bool? differentOddEven,
    int? pageNumberStart,
    Color? backgroundColor,
    String? watermarkText,
  }) {
    return SectionModel(
      id: id ?? this.id,
      pageSize: pageSize ?? this.pageSize,
      margins: margins ?? this.margins,
      isLandscape: isLandscape ?? this.isLandscape,
      columnCount: columnCount ?? this.columnCount,
      columnSpacing: columnSpacing ?? this.columnSpacing,
      breakType: breakType ?? this.breakType,
      differentFirstPage: differentFirstPage ?? this.differentFirstPage,
      differentOddEven: differentOddEven ?? this.differentOddEven,
      pageNumberStart: pageNumberStart ?? this.pageNumberStart,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      watermarkText: watermarkText ?? this.watermarkText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageSize': pageSize.name,
      'width': pageSize.width,
      'height': pageSize.height,
      'margins': {
        'top': margins.top,
        'bottom': margins.bottom,
        'left': margins.left,
        'right': margins.right,
      },
      'isLandscape': isLandscape,
      'columnCount': columnCount,
      'columnSpacing': columnSpacing,
      'breakType': breakType.index,
      'differentFirstPage': differentFirstPage,
      'differentOddEven': differentOddEven,
      'pageNumberStart': pageNumberStart,
      'backgroundColor': backgroundColor?.value,
      'watermarkText': watermarkText,
    };
  }

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as String,
      pageSize: PageSize.presets.firstWhere(
        (p) => p.name == json['pageSize'],
        orElse: () => PageSize.A4,
      ),
      margins: SectionMargins(
        top: (json['margins']['top'] as num).toDouble(),
        bottom: (json['margins']['bottom'] as num).toDouble(),
        left: (json['margins']['left'] as num).toDouble(),
        right: (json['margins']['right'] as num).toDouble(),
      ),
      isLandscape: json['isLandscape'] as bool? ?? false,
      columnCount: json['columnCount'] as int? ?? 1,
      columnSpacing: (json['columnSpacing'] as num?)?.toDouble() ?? 24.0,
      breakType: SectionBreakType.values[json['breakType'] as int? ?? 0],
      differentFirstPage: json['differentFirstPage'] as bool? ?? false,
      differentOddEven: json['differentOddEven'] as bool? ?? false,
      pageNumberStart: json['pageNumberStart'] as int? ?? 1,
      backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
      watermarkText: json['watermarkText'] as String?,
    );
  }
}
