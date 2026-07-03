import 'cell_style.dart';
import 'cell_validation.dart';

class CellData {
  final String value;
  final CellStyle style;
  final String? formula;
  final CellValidation? validation;
  final String? comment;
  final String? hyperlink;

  CellData({
    this.value = '',
    CellStyle? style,
    this.formula,
    this.validation,
    this.comment,
    this.hyperlink,
  }) : style = style ?? CellStyle();

  CellData copyWith({
    String? value,
    CellStyle? style,
    String? formula,
    CellValidation? validation,
    String? comment,
    String? hyperlink,
    bool clearFormula = false,
    bool clearValidation = false,
    bool clearComment = false,
    bool clearHyperlink = false,
  }) {
    return CellData(
      value: value ?? this.value,
      style: style ?? this.style,
      formula: clearFormula ? null : (formula ?? this.formula),
      validation: clearValidation ? null : (validation ?? this.validation),
      comment: clearComment ? null : (comment ?? this.comment),
      hyperlink: clearHyperlink ? null : (hyperlink ?? this.hyperlink),
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'style': style.toJson(),
    if (formula != null) 'formula': formula,
    if (validation != null) 'validation': validation!.toJson(),
    if (comment != null) 'comment': comment,
    if (hyperlink != null) 'hyperlink': hyperlink,
  };

  factory CellData.fromJson(Map<String, dynamic> json) => CellData(
    value: json['value'] ?? '',
    style: CellStyle.fromJson(json['style'] ?? {}),
    formula: json['formula'],
    validation: json['validation'] != null
        ? CellValidation.fromJson(json['validation'])
        : null,
    comment: json['comment'],
    hyperlink: json['hyperlink'],
  );
}
