
        
             




// ==================== PRESENTER VIEW ====================
    

  Widget _buildRotateHandle() {
    return Positioned(
      top: -40,
      left: widget.component.size.width / 2 - 15,
      child: GestureDetector(
        onPanStart: (details) {
          rotationStart = widget.component.rotation;
        },
        onPanUpdate: (details) {
          if (rotationStart == null) return;

          final center = Offset(
            widget.component.size.width / 2,
            widget.component.size.height / 2 + 40,
          );

          final angle = math.atan2(
            details.localPosition.dy - center.dy,
            details.localPosition.dx - center.dx,
          );

          final rotation = (angle * 180 / math.pi) + 90;

          ref
              .read(presentationProvider.notifier)
              .updateComponent(
                widget.component.id,
                widget.component.copyWith(rotation: rotation),
              );
        },
        onPanEnd: (_) {
          rotationStart = null;
          ref
              .read(historyProvider.notifier)
              .addState(ref.read(presentationProvider));
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 18),
        ),
      ),
    );
  }

// ==================== ANIMATED GRADIENT CONTAINER ====================


// ==================== CHART WIDGETS ====================


// ==================== SLIDE PANEL ====================

// ==================== PROPERTIES PANEL ====================



// ==================== CANVAS AREA ====================


// ==================== PARTICLE BACKGROUND ====================

// ==================== RULERS ====================



// ==================== MODERN RESIZABLE COMPONENT ====================


// ==================== MODERN TOOLBAR ====================
// pubspec.yaml dependencies:
// flutter_riverpod: ^2.4.9
// uuid: ^4.2.2
// file_picker: ^6.1.1
// path_provider: ^2.1.1
// archive: ^3.4.9
// xml: ^6.4.2
// image: ^4.1.3
// flex_color_picker: ^3.3.0
// google_fonts: ^6.1.0
// lottie: ^3.0.0
// flutter_animate: ^4.5.0
// glassmorphism: ^3.0.0
// video_player: ^2.8.0
// audioplayers: ^5.2.1
// shimmer: ^3.0.0

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== ENUMS & TYPES ====================






// ==================== ADVANCED MODELS ====================



// ==================== STATE PROVIDERS ====================

// ==================== MAIN APP ====================

