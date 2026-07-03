import 'package:flutter/material.dart';

class KySheetColors {
  const KySheetColors._();

  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const gridLine = Color(0xFFE2E8F0);
  static const gridLineStrong = Color(0xFFCBD5E1);
  static const text = Color(0xFF0F172A);
  static const mutedText = Color(0xFF64748B);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEFF6FF);
  static const headerActive = Color(0xFFDBEAFE);
  static const formula = Color(0xFF0891B2);
  static const comment = Color(0xFFF59E0B);
  static const validationError = Color(0xFFDC2626);
  static const validationSoft = Color(0xFFFEF2F2);
}

class KySheetMetrics {
  const KySheetMetrics._();

  static const rowHeaderWidth = 56.0;
  static const headerHeight = 34.0;
  static const defaultRowHeight = 38.0;
  static const defaultColumnWidth = 112.0;
  static const minRowHeight = 24.0;
  static const maxRowHeight = 220.0;
  static const minColumnWidth = 56.0;
  static const maxColumnWidth = 520.0;
}

class KySheetTextStyles {
  const KySheetTextStyles._();

  static const header = TextStyle(
    color: KySheetColors.mutedText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const cell = TextStyle(
    color: KySheetColors.text,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}
