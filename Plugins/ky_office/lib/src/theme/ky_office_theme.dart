import 'package:flutter/material.dart';

class KyOfficeColors {
  const KyOfficeColors._();

  static const brand = Color(0xFF334155);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const focus = Color(0xFF2563EB);
}

class KyOfficeRadius {
  const KyOfficeRadius._();

  static const small = 6.0;
  static const medium = 8.0;
}

class KyOfficeSpacing {
  const KyOfficeSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class KyOfficeTheme {
  const KyOfficeTheme._();

  static ThemeData light({Color seedColor = KyOfficeColors.brand}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KyOfficeColors.surfaceMuted,
      fontFamily: 'Inter',
      dividerColor: KyOfficeColors.border,
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          color: KyOfficeColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(
          color: KyOfficeColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: KyOfficeColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
