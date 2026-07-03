import 'package:flutter/material.dart';
import 'package:ky_office_core/ky_office_core.dart';

import 'ky_office_theme.dart';

class OfficeProductVisuals {
  const OfficeProductVisuals({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  static OfficeProductVisuals forProduct(KyOfficeProductDescriptor product) {
    return switch (product.id) {
      'docs' => const OfficeProductVisuals(
        icon: Icons.description_outlined,
        accentColor: Color(0xFF2563EB),
      ),
      'sheets' => const OfficeProductVisuals(
        icon: Icons.grid_on_outlined,
        accentColor: Color(0xFF059669),
      ),
      'slides' => const OfficeProductVisuals(
        icon: Icons.slideshow_outlined,
        accentColor: Color(0xFFEA580C),
      ),
      'pdf' => const OfficeProductVisuals(
        icon: Icons.picture_as_pdf_outlined,
        accentColor: Color(0xFFDC2626),
      ),
      _ => const OfficeProductVisuals(
        icon: Icons.insert_drive_file_outlined,
        accentColor: KyOfficeColors.brand,
      ),
    };
  }
}
