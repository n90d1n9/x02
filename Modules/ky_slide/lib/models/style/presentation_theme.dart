import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums.dart';

class PresentationTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final List<Color> colorPalette;
  final VisualEffect defaultEffect;

  PresentationTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.titleStyle,
    required this.bodyStyle,
    required this.colorPalette,
    this.defaultEffect = VisualEffect.none,
  });

  static PresentationTheme get modernGlass => PresentationTheme(
    id: 'modern_glass',
    name: 'Modern Glass',
    primaryColor: const Color(0xFF6366F1),
    secondaryColor: const Color(0xFF8B5CF6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: GoogleFonts.inter(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyStyle: GoogleFonts.inter(fontSize: 20, color: Colors.white70),
    colorPalette: [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ],
    defaultEffect: VisualEffect.glassmorphism,
  );

  static PresentationTheme get neonCyber => PresentationTheme(
    id: 'neon_cyber',
    name: 'Neon Cyber',
    primaryColor: const Color(0xFF00F0FF),
    secondaryColor: const Color(0xFFFF006E),
    backgroundColor: const Color(0xFF0A0E27),
    textColor: const Color(0xFF00F0FF),
    titleStyle: GoogleFonts.orbitron(
      fontSize: 52,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00F0FF),
      shadows: [Shadow(color: Color(0xFF00F0FF), blurRadius: 20)],
    ),
    bodyStyle: GoogleFonts.rajdhani(fontSize: 22, color: Colors.white),
    colorPalette: [
      const Color(0xFF00F0FF),
      const Color(0xFFFF006E),
      const Color(0xFF8338EC),
      const Color(0xFFFB5607),
      const Color(0xFFFFBE0B),
    ],
    defaultEffect: VisualEffect.neon,
  );

  static PresentationTheme get softNeumorphic => PresentationTheme(
    id: 'soft_neumorphic',
    name: 'Soft Neumorphic',
    primaryColor: const Color(0xFF667EEA),
    secondaryColor: const Color(0xFF764BA2),
    backgroundColor: const Color(0xFFE0E5EC),
    textColor: const Color(0xFF333333),
    titleStyle: GoogleFonts.poppins(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF333333),
    ),
    bodyStyle: GoogleFonts.poppins(
      fontSize: 18,
      color: const Color(0xFF555555),
    ),
    colorPalette: [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFFF093FB),
      const Color(0xFF4FACFE),
      const Color(0xFF00F2FE),
    ],
    defaultEffect: VisualEffect.neumorphism,
  );

  static List<PresentationTheme> get allThemes => [
    modernGlass,
    neonCyber,
    softNeumorphic,
  ];
}
