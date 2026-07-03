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

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== MODELS ====================

enum ComponentType { text, image, shape, line, circle, triangle }

enum AnimationType { none, fadeIn, slideIn, zoom, bounce }

enum ToolMode { select, text, image, shape, line }

class PresentationComponent {
  final String id;
  final ComponentType type;
  final Offset position;
  final Size size;
  final String? text;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final Uint8List? imageData;
  final Color? backgroundColor;
  final double rotation;
  final int zIndex;
  final AnimationType animation;
  final double opacity;
  final BorderSide? border;
  final bool isEditing;

  PresentationComponent({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.text,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.imageData,
    this.backgroundColor,
    this.rotation = 0,
    this.zIndex = 0,
    this.animation = AnimationType.none,
    this.opacity = 1.0,
    this.border,
    this.isEditing = false,
  });

  PresentationComponent copyWith({
    Offset? position,
    Size? size,
    String? text,
    TextStyle? textStyle,
    TextAlign? textAlign,
    Uint8List? imageData,
    Color? backgroundColor,
    double? rotation,
    int? zIndex,
    AnimationType? animation,
    double? opacity,
    BorderSide? border,
    bool? isEditing,
  }) {
    return PresentationComponent(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      textAlign: textAlign ?? this.textAlign,
      imageData: imageData ?? this.imageData,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      animation: animation ?? this.animation,
      opacity: opacity ?? this.opacity,
      border: border ?? this.border,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class Slide {
  final String id;
  final List<PresentationComponent> components;
  final Color backgroundColor;
  final String? notes;
  final String? title;

  Slide({
    required this.id,
    required this.components,
    this.backgroundColor = Colors.white,
    this.notes,
    this.title,
  });

  Slide copyWith({
    List<PresentationComponent>? components,
    Color? backgroundColor,
    String? notes,
    String? title,
  }) {
    return Slide(
      id: id,
      components: components ?? this.components,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      notes: notes ?? this.notes,
      title: title ?? this.title,
    );
  }
}

class HistoryState {
  final Presentation presentation;
  final DateTime timestamp;

  HistoryState(this.presentation, this.timestamp);
}

class Presentation {
  final String id;
  final String title;
  final List<Slide> slides;
  final int currentSlideIndex;

  Presentation({
    required this.id,
    required this.title,
    required this.slides,
    this.currentSlideIndex = 0,
  });

  Presentation copyWith({
    String? title,
    List<Slide>? slides,
    int? currentSlideIndex,
  }) {
    return Presentation(
      id: id,
      title: title ?? this.title,
      slides: slides ?? this.slides,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
    );
  }
}

// ==================== STATE PROVIDERS ====================

final presentationProvider =
    StateNotifierProvider<PresentationNotifier, Presentation>((ref) {
      return PresentationNotifier();
    });

class PresentationNotifier extends StateNotifier<Presentation> {
  PresentationNotifier()
    : super(
        Presentation(
          id: const Uuid().v4(),
          title: 'New Presentation',
          slides: [
            Slide(id: const Uuid().v4(), components: [], title: 'Slide 1'),
          ],
        ),
      );

  void addSlide() {
    final slideNum = state.slides.length + 1;
    state = state.copyWith(
      slides: [
        ...state.slides,
        Slide(id: const Uuid().v4(), components: [], title: 'Slide $slideNum'),
      ],
    );
  }

  void duplicateSlide(int index) {
    final slide = state.slides[index];
    final newComponents = slide.components
        .map(
          (c) => PresentationComponent(
            id: const Uuid().v4(),
            type: c.type,
            position: c.position,
            size: c.size,
            text: c.text,
            textStyle: c.textStyle,
            textAlign: c.textAlign,
            imageData: c.imageData,
            backgroundColor: c.backgroundColor,
            rotation: c.rotation,
            zIndex: c.zIndex,
            animation: c.animation,
            opacity: c.opacity,
            border: c.border,
          ),
        )
        .toList();

    final newSlide = Slide(
      id: const Uuid().v4(),
      components: newComponents,
      backgroundColor: slide.backgroundColor,
      notes: slide.notes,
      title: '${slide.title} (Copy)',
    );

    final slides = List<Slide>.from(state.slides);
    slides.insert(index + 1, newSlide);
    state = state.copyWith(slides: slides);
  }

  void deleteSlide(int index) {
    if (state.slides.length <= 1) return;
    final slides = List<Slide>.from(state.slides);
    slides.removeAt(index);
    state = state.copyWith(
      slides: slides,
      currentSlideIndex: state.currentSlideIndex >= slides.length
          ? slides.length - 1
          : state.currentSlideIndex,
    );
  }

  void reorderSlides(int oldIndex, int newIndex) {
    final slides = List<Slide>.from(state.slides);
    if (newIndex > oldIndex) newIndex--;
    final slide = slides.removeAt(oldIndex);
    slides.insert(newIndex, slide);

    int newCurrentIndex = state.currentSlideIndex;
    if (oldIndex == state.currentSlideIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentSlideIndex &&
        newIndex >= state.currentSlideIndex) {
      newCurrentIndex--;
    } else if (oldIndex > state.currentSlideIndex &&
        newIndex <= state.currentSlideIndex) {
      newCurrentIndex++;
    }

    state = state.copyWith(slides: slides, currentSlideIndex: newCurrentIndex);
  }

  void setCurrentSlide(int index) {
    state = state.copyWith(currentSlideIndex: index);
  }

  void addComponent(PresentationComponent component) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.isEmpty
        ? 0
        : currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final newComponent = component.copyWith(zIndex: maxZ + 1);
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: [...currentSlide.components, newComponent],
    );
    state = state.copyWith(slides: slides);
  }

  void updateComponent(String componentId, PresentationComponent updated) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components
        .map((c) => c.id == componentId ? updated : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void deleteComponent(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final components = currentSlide.components
        .where((c) => c.id != componentId)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void bringToFront(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final maxZ = currentSlide.components.map((c) => c.zIndex).reduce(math.max);
    final components = currentSlide.components
        .map((c) => c.id == componentId ? c.copyWith(zIndex: maxZ + 1) : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void sendToBack(String componentId) {
    final slides = List<Slide>.from(state.slides);
    final currentSlide = slides[state.currentSlideIndex];
    final minZ = currentSlide.components.map((c) => c.zIndex).reduce(math.min);
    final components = currentSlide.components
        .map((c) => c.id == componentId ? c.copyWith(zIndex: minZ - 1) : c)
        .toList();
    slides[state.currentSlideIndex] = currentSlide.copyWith(
      components: components,
    );
    state = state.copyWith(slides: slides);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setSlideBackground(Color color) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      backgroundColor: color,
    );
    state = state.copyWith(slides: slides);
  }

  void setSlideTitle(String title) {
    final slides = List<Slide>.from(state.slides);
    slides[state.currentSlideIndex] = slides[state.currentSlideIndex].copyWith(
      title: title,
    );
    state = state.copyWith(slides: slides);
  }

  void loadPresentation(Presentation presentation) {
    state = presentation;
  }
}

final selectedComponentProvider = StateProvider<String?>((ref) => null);
final presenterModeProvider = StateProvider<bool>((ref) => false);
final currentToolProvider = StateProvider<ToolMode>((ref) => ToolMode.select);
final showRulerProvider = StateProvider<bool>((ref) => true);
final showGridProvider = StateProvider<bool>((ref) => false);
final snapToGridProvider = StateProvider<bool>((ref) => false);
final zoomLevelProvider = StateProvider<double>((ref) => 1.0);

// Undo/Redo History
final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryState>>((ref) {
      return HistoryNotifier(ref);
    });

class HistoryNotifier extends StateNotifier<List<HistoryState>> {
  final Ref ref;
  int currentIndex = -1;

  HistoryNotifier(this.ref) : super([]);

  void addState(Presentation presentation) {
    if (currentIndex < state.length - 1) {
      state = state.sublist(0, currentIndex + 1);
    }

    state = [...state, HistoryState(presentation, DateTime.now())];
    currentIndex++;

    if (state.length > 50) {
      state = state.sublist(state.length - 50);
      currentIndex = state.length - 1;
    }
  }

  void undo() {
    if (currentIndex > 0) {
      currentIndex--;
      ref
          .read(presentationProvider.notifier)
          .loadPresentation(state[currentIndex].presentation);
    }
  }

  void redo() {
    if (currentIndex < state.length - 1) {
      currentIndex++;
      ref
          .read(presentationProvider.notifier)
          .loadPresentation(state[currentIndex].presentation);
    }
  }

  bool get canUndo => currentIndex > 0;
  bool get canRedo => currentIndex < state.length - 1;
}

// ==================== PPT EXPORT SERVICE ====================

class PptService {
  static Future<void> exportToPpt(Presentation presentation) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pptxPath = '${directory.path}/${presentation.title}.pptx';

      final archive = Archive();

      archive.addFile(
        _createFile('[Content_Types].xml', _contentTypesXml(presentation)),
      );
      archive.addFile(_createFile('_rels/.rels', _relsXml()));
      archive.addFile(
        _createFile(
          'ppt/_rels/presentation.xml.rels',
          _presentationRelsXml(presentation),
        ),
      );
      archive.addFile(
        _createFile('ppt/presentation.xml', _presentationXml(presentation)),
      );

      for (int i = 0; i < presentation.slides.length; i++) {
        final slide = presentation.slides[i];
        archive.addFile(
          _createFile('ppt/slides/slide${i + 1}.xml', _slideXml(slide, i + 1)),
        );
        archive.addFile(
          _createFile(
            'ppt/slides/_rels/slide${i + 1}.xml.rels',
            _slideRelsXml(slide, i + 1),
          ),
        );
      }

      int imageIndex = 1;
      for (final slide in presentation.slides) {
        for (final component in slide.components) {
          if (component.type == ComponentType.image &&
              component.imageData != null) {
            archive.addFile(
              ArchiveFile(
                'ppt/media/image$imageIndex.png',
                component.imageData!.length,
                component.imageData,
              ),
            );
            imageIndex++;
          }
        }
      }

      final zipEncoder = ZipEncoder();
      final bytes = zipEncoder.encode(archive);
      await File(pptxPath).writeAsBytes(bytes!);

      print('Presentation exported to: $pptxPath');
    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }

  static ArchiveFile _createFile(String name, String content) {
    final bytes = content.codeUnits;
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _contentTypesXml(Presentation presentation) {
    final buffer = StringBuffer(
      '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>''',
    );

    for (int i = 0; i < presentation.slides.length; i++) {
      buffer.write(
        '<Override PartName="/ppt/slides/slide${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>',
      );
    }

    buffer.write('</Types>');
    return buffer.toString();
  }

  static String _relsXml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
  }

  static String _presentationRelsXml(Presentation presentation) {
    final buffer = StringBuffer(
      '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">''',
    );

    for (int i = 0; i < presentation.slides.length; i++) {
      buffer.write(
        '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>',
      );
    }

    buffer.write('</Relationships>');
    return buffer.toString();
  }

  static String _presentationXml(Presentation presentation) {
    final buffer = StringBuffer('''<?xml version="1.0" encoding="UTF-8"?>
<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:sldIdLst>''');

    for (int i = 0; i < presentation.slides.length; i++) {
      buffer.write('<p:sldId id="${256 + i}" r:id="rId${i + 1}"/>');
    }

    buffer.write('''
  </p:sldIdLst>
  <p:sldSz cx="9144000" cy="6858000"/>
</p:presentation>''');
    return buffer.toString();
  }

  static String _slideXml(Slide slide, int slideNumber) {
    final bgColor = _colorToHex(slide.backgroundColor);
    final buffer = StringBuffer('''<?xml version="1.0" encoding="UTF-8"?>
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="$bgColor"/></a:solidFill>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr/>''');

    final sortedComponents = List<PresentationComponent>.from(slide.components)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    int shapeId = 2;
    for (final component in sortedComponents) {
      if (component.type == ComponentType.text) {
        buffer.write(_textBoxXml(component, shapeId++));
      } else if (component.type == ComponentType.shape ||
          component.type == ComponentType.circle ||
          component.type == ComponentType.triangle) {
        buffer.write(_shapeXml(component, shapeId++));
      }
    }

    buffer.write('''
    </p:spTree>
  </p:cSld>
</p:sld>''');
    return buffer.toString();
  }

  static String _textBoxXml(PresentationComponent component, int id) {
    final x = (component.position.dx * 9144).toInt();
    final y = (component.position.dy * 9144).toInt();
    final w = (component.size.width * 9144).toInt();
    final h = (component.size.height * 9144).toInt();
    final fontSize = ((component.textStyle?.fontSize ?? 16) * 100).toInt();
    final fontColor = _colorToHex(component.textStyle?.color ?? Colors.black);
    final rotation = (component.rotation * 60000).toInt();

    return '''
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="$id" name="TextBox $id"/>
          <p:cNvSpPr txBox="1"/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm rot="$rotation">
            <a:off x="$x" y="$y"/>
            <a:ext cx="$w" cy="$h"/>
          </a:xfrm>
          <a:prstGeom prst="rect"/>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:p>
            <a:r>
              <a:rPr sz="$fontSize"><a:solidFill><a:srgbClr val="$fontColor"/></a:solidFill></a:rPr>
              <a:t>${_escapeXml(component.text ?? '')}</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>''';
  }

  static String _shapeXml(PresentationComponent component, int id) {
    final x = (component.position.dx * 9144).toInt();
    final y = (component.position.dy * 9144).toInt();
    final w = (component.size.width * 9144).toInt();
    final h = (component.size.height * 9144).toInt();
    final fillColor = _colorToHex(component.backgroundColor ?? Colors.blue);
    final rotation = (component.rotation * 60000).toInt();

    String shapeType = 'rect';
    if (component.type == ComponentType.circle) shapeType = 'ellipse';
    if (component.type == ComponentType.triangle) shapeType = 'triangle';

    return '''
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="$id" name="Shape $id"/>
          <p:cNvSpPr/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm rot="$rotation">
            <a:off x="$x" y="$y"/>
            <a:ext cx="$w" cy="$h"/>
          </a:xfrm>
          <a:prstGeom prst="$shapeType">
            <a:avLst/>
          </a:prstGeom>
          <a:solidFill><a:srgbClr val="$fillColor"/></a:solidFill>
        </p:spPr>
      </p:sp>''';
  }

  static String _slideRelsXml(Slide slide, int slideNumber) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
  }

  static String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// ==================== UI COMPONENTS ====================

void main() {
  runApp(const ProviderScope(child: PresentationApp()));
}

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Presentation Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const PresentationEditor(),
    );
  }
}

class PresentationEditor extends ConsumerWidget {
  const PresentationEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final isPresenterMode = ref.watch(presenterModeProvider);

    if (isPresenterMode) {
      return const PresenterView();
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete) {
            final selected = ref.read(selectedComponentProvider);
            if (selected != null) {
              ref.read(presentationProvider.notifier).deleteComponent(selected);
              ref.read(selectedComponentProvider.notifier).state = null;
            }
            return KeyEventResult.handled;
          } else if (HardwareKeyboard.instance.isControlPressed) {
            if (event.logicalKey == LogicalKeyboardKey.keyZ) {
              ref.read(historyProvider.notifier).undo();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
              ref.read(historyProvider.notifier).redo();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(presentation.title),
              const SizedBox(width: 16),
              Text(
                'Slide ${presentation.currentSlideIndex + 1}/${presentation.slides.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: ref.watch(historyProvider.notifier).canUndo
                  ? () => ref.read(historyProvider.notifier).undo()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: ref.watch(historyProvider.notifier).canRedo
                  ? () => ref.read(historyProvider.notifier).redo()
                  : null,
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.slideshow),
              tooltip: 'Presenter Mode (F5)',
              onPressed: () {
                ref.read(presenterModeProvider.notifier).state = true;
              },
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Import PPT',
              onPressed: () => _importPpt(ref),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export to PPT',
              onPressed: () => PptService.exportToPpt(presentation),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: const SlidePanel(),
            ),
            Expanded(
              child: Column(
                children: [
                  const Toolbar(),
                  Expanded(
                    child: Stack(
                      children: [
                        const SlideCanvas(),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: ZoomControls(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: const PropertiesPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPpt(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx'],
    );

    if (result != null && result.files.single.path != null) {
      // Import implementation would go here
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('PPT import feature coming soon!')),
      );
    }
  }
}

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final showRuler = ref.watch(showRulerProvider);
    final showGrid = ref.watch(showGridProvider);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.near_me,
            label: 'Select',
            isSelected: currentTool == ToolMode.select,
            onPressed: () =>
                ref.read(currentToolProvider.notifier).state = ToolMode.select,
          ),
          _ToolButton(
            icon: Icons.text_fields,
            label: 'Text',
            isSelected: currentTool == ToolMode.text,
            onPressed: () =>
                ref.read(currentToolProvider.notifier).state = ToolMode.text,
          ),
          _ToolButton(
            icon: Icons.image,
            label: 'Image',
            isSelected: currentTool == ToolMode.image,
            onPressed: () async {
              ref.read(currentToolProvider.notifier).state = ToolMode.image;
              await _addImage(ref);
              ref.read(currentToolProvider.notifier).state = ToolMode.select;
            },
          ),
          _ToolButton(
            icon: Icons.crop_square,
            label: 'Shape',
            isSelected: currentTool == ToolMode.shape,
            onPressed: () => _showShapeMenu(context, ref),
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.flip_to_front),
            tooltip: 'Bring to Front',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).bringToFront(selected);
                ref
                    .read(historyProvider.notifier)
                    .addState(ref.read(presentationProvider));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_to_back),
            tooltip: 'Send to Back',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).sendToBack(selected);
                ref
                    .read(historyProvider.notifier)
                    .addState(ref.read(presentationProvider));
              }
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: Icon(
              showRuler ? Icons.straighten : Icons.straighten_outlined,
            ),
            tooltip: 'Toggle Ruler',
            color: showRuler ? Colors.blue : null,
            onPressed: () {
              ref.read(showRulerProvider.notifier).state = !showRuler;
            },
          ),
          IconButton(
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Toggle Grid',
            color: showGrid ? Colors.blue : null,
            onPressed: () {
              ref.read(showGridProvider.notifier).state = !showGrid;
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete (Del)',
            onPressed: () => _deleteSelected(ref),
          ),
          const Spacer(),
          Text('${ref.watch(zoomLevelProvider).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  void _showShapeMenu(BuildContext context, WidgetRef ref) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 60, 0, 0),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.crop_square),
              SizedBox(width: 8),
              Text('Rectangle'),
            ],
          ),
          onTap: () => _addShape(ref, ComponentType.shape),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.circle_outlined),
              SizedBox(width: 8),
              Text('Circle'),
            ],
          ),
          onTap: () => _addShape(ref, ComponentType.circle),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.change_history),
              SizedBox(width: 8),
              Text('Triangle'),
            ],
          ),
          onTap: () => _addShape(ref, ComponentType.triangle),
        ),
      ],
    );
  }

  void _addShape(WidgetRef ref, ComponentType type) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: type,
      position: const Offset(200, 200),
      size: const Size(150, 150),
      backgroundColor: Colors.blue,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
  }

  Future<void> _addImage(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final component = PresentationComponent(
          id: const Uuid().v4(),
          type: ComponentType.image,
          position: const Offset(200, 200),
          size: const Size(300, 200),
          imageData: result.files.single.bytes,
        );
        ref.read(presentationProvider.notifier).addComponent(component);
        ref.read(selectedComponentProvider.notifier).state = component.id;
        ref
            .read(historyProvider.notifier)
            .addState(ref.read(presentationProvider));
      }
    } catch (e) {
      print('Error adding image: $e');
    }
  }

  void _deleteSelected(WidgetRef ref) {
    final selected = ref.read(selectedComponentProvider);
    if (selected != null) {
      ref.read(presentationProvider.notifier).deleteComponent(selected);
      ref.read(selectedComponentProvider.notifier).state = null;
      ref
          .read(historyProvider.notifier)
          .addState(ref.read(presentationProvider));
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(zoomLevelProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom - 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          Text(
            '${(zoom * 100).toInt()}%',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 20,
            onPressed: () {
              final newZoom = (zoom + 0.1).clamp(0.25, 3.0);
              ref.read(zoomLevelProvider.notifier).state = newZoom;
            },
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            iconSize: 20,
            tooltip: 'Fit to Screen',
            onPressed: () {
              ref.read(zoomLevelProvider.notifier).state = 1.0;
            },
          ),
        ],
      ),
    );
  }
}

class SlideCanvas extends ConsumerStatefulWidget {
  const SlideCanvas({super.key});

  @override
  ConsumerState<SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends ConsumerState<SlideCanvas> {
  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final sortedComponents = List<PresentationComponent>.from(
      currentSlide.components,
    )..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final zoom = ref.watch(zoomLevelProvider);
    final showRuler = ref.watch(showRulerProvider);
    final showGrid = ref.watch(showGridProvider);
    final currentTool = ref.watch(currentToolProvider);

    return Container(
      color: Colors.grey[300],
      child: Column(
        children: [
          if (showRuler) const HorizontalRuler(),
          Expanded(
            child: Row(
              children: [
                if (showRuler) const VerticalRuler(),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.25,
                    maxScale: 3.0,
                    scaleEnabled: false,
                    panEnabled: false,
                    child: Center(
                      child: Transform.scale(
                        scale: zoom,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: GestureDetector(
                            onTapDown: (details) {
                              final localPos = details.localPosition;
                              if (currentTool == ToolMode.text) {
                                _addTextBox(localPos);
                              } else {
                                ref
                                        .read(
                                          selectedComponentProvider.notifier,
                                        )
                                        .state =
                                    null;
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: currentSlide.backgroundColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  if (showGrid) const GridPainter(),
                                  ...sortedComponents
                                      .map(
                                        (c) => ResizableComponent(component: c),
                                      )
                                      .toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addTextBox(Offset position) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.text,
      position: position,
      size: const Size(200, 100),
      text: 'Double click to edit',
      textStyle: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
      backgroundColor: Colors.transparent,
      isEditing: false,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
    ref.read(currentToolProvider.notifier).state = ToolMode.select;
  }
}

class HorizontalRuler extends StatelessWidget {
  const HorizontalRuler({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      color: Colors.grey[200],
      child: CustomPaint(painter: RulerPainter(isHorizontal: true)),
    );
  }
}

class VerticalRuler extends StatelessWidget {
  const VerticalRuler({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      color: Colors.grey[200],
      child: CustomPaint(painter: RulerPainter(isHorizontal: false)),
    );
  }
}

class RulerPainter extends CustomPainter {
  final bool isHorizontal;

  RulerPainter({required this.isHorizontal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (isHorizontal) {
      for (int i = 0; i < size.width; i += 10) {
        final height = i % 50 == 0 ? 10.0 : (i % 10 == 0 ? 6.0 : 3.0);
        canvas.drawLine(
          Offset(i.toDouble(), size.height - height),
          Offset(i.toDouble(), size.height),
          paint,
        );

        if (i % 100 == 0 && i > 0) {
          textPainter.text = TextSpan(
            text: i.toString(),
            style: const TextStyle(fontSize: 9, color: Colors.black87),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(i - 10, 2));
        }
      }
    } else {
      for (int i = 0; i < size.height; i += 10) {
        final width = i % 50 == 0 ? 10.0 : (i % 10 == 0 ? 6.0 : 3.0);
        canvas.drawLine(
          Offset(size.width - width, i.toDouble()),
          Offset(size.width, i.toDouble()),
          paint,
        );

        if (i % 100 == 0 && i > 0) {
          textPainter.text = TextSpan(
            text: i.toString(),
            style: const TextStyle(fontSize: 9, color: Colors.black87),
          );
          textPainter.layout();
          canvas.save();
          canvas.translate(2, i.toDouble());
          canvas.rotate(-math.pi / 2);
          textPainter.paint(canvas, const Offset(0, 0));
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(RulerPainter oldDelegate) => false;
}

class GridPainter extends StatelessWidget {
  const GridPainter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), child: Container());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class ResizableComponent extends ConsumerStatefulWidget {
  final PresentationComponent component;

  const ResizableComponent({super.key, required this.component});

  @override
  ConsumerState<ResizableComponent> createState() => _ResizableComponentState();
}

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  rotate,
}

class _ResizableComponentState extends ConsumerState<ResizableComponent> {
  Offset? dragStart;
  Size? resizeStart;
  Offset? positionStart;
  ResizeHandle? activeHandle;
  double? rotationStart;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.component.text ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected =
        ref.watch(selectedComponentProvider) == widget.component.id;
    final snapToGrid = ref.watch(snapToGridProvider);

    return Positioned(
      left: widget.component.position.dx,
      top: widget.component.position.dy,
      child: Transform.rotate(
        angle: widget.component.rotation * math.pi / 180,
        child: GestureDetector(
          onTap: () {
            ref.read(selectedComponentProvider.notifier).state =
                widget.component.id;
          },
          onDoubleTap: () {
            if (widget.component.type == ComponentType.text) {
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    widget.component.id,
                    widget.component.copyWith(isEditing: true),
                  );
              _focusNode.requestFocus();
            }
          },
          onPanStart: (details) {
            if (!isSelected) return;
            dragStart = details.localPosition;
            positionStart = widget.component.position;
          },
          onPanUpdate: (details) {
            if (!isSelected || dragStart == null || positionStart == null)
              return;
            var delta = details.localPosition - dragStart!;
            var newPosition = positionStart! + delta;

            if (snapToGrid) {
              newPosition = Offset(
                (newPosition.dx / 20).round() * 20.0,
                (newPosition.dy / 20).round() * 20.0,
              );
            }

            ref
                .read(presentationProvider.notifier)
                .updateComponent(
                  widget.component.id,
                  widget.component.copyWith(position: newPosition),
                );
          },
          onPanEnd: (_) {
            ref
                .read(historyProvider.notifier)
                .addState(ref.read(presentationProvider));
          },
          child: Opacity(
            opacity: widget.component.opacity,
            child: Container(
              width: widget.component.size.width,
              height: widget.component.size.height,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : widget.component.border != null
                    ? Border.fromBorderSide(widget.component.border!)
                    : null,
                color: widget.component.backgroundColor,
              ),
              child: Stack(
                children: [
                  _buildComponentContent(),
                  if (isSelected) ..._buildResizeHandles(),
                  if (isSelected) _buildRotateHandle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComponentContent() {
    switch (widget.component.type) {
      case ComponentType.text:
        if (widget.component.isEditing) {
          return TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: widget.component.textStyle,
            textAlign: widget.component.textAlign,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (value) {
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    widget.component.id,
                    widget.component.copyWith(text: value),
                  );
            },
            onSubmitted: (_) {
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    widget.component.id,
                    widget.component.copyWith(isEditing: false),
                  );
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
            },
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.component.text ?? '',
              style: widget.component.textStyle,
              textAlign: widget.component.textAlign,
            ),
          );
        }
      case ComponentType.image:
        return widget.component.imageData != null
            ? Image.memory(
                widget.component.imageData!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              );
      case ComponentType.shape:
        return Container(color: widget.component.backgroundColor);
      case ComponentType.circle:
        return Container(
          decoration: BoxDecoration(
            color: widget.component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: TrianglePainter(
            widget.component.backgroundColor ?? Colors.blue,
          ),
        );
      case ComponentType.line:
        return CustomPaint(
          painter: LinePainter(
            widget.component.backgroundColor ?? Colors.black,
          ),
        );
    }
  }

  List<Widget> _buildResizeHandles() {
    return [
      _buildHandle(ResizeHandle.topLeft, Alignment.topLeft),
      _buildHandle(ResizeHandle.topRight, Alignment.topRight),
      _buildHandle(ResizeHandle.bottomLeft, Alignment.bottomLeft),
      _buildHandle(ResizeHandle.bottomRight, Alignment.bottomRight),
      _buildHandle(ResizeHandle.top, Alignment.topCenter),
      _buildHandle(ResizeHandle.bottom, Alignment.bottomCenter),
      _buildHandle(ResizeHandle.left, Alignment.centerLeft),
      _buildHandle(ResizeHandle.right, Alignment.centerRight),
    ];
  }

  Widget _buildHandle(ResizeHandle handle, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: (details) {
          activeHandle = handle;
          resizeStart = widget.component.size;
          positionStart = widget.component.position;
        },
        onPanUpdate: (details) {
          if (activeHandle == null ||
              resizeStart == null ||
              positionStart == null)
            return;

          double newWidth = resizeStart!.width;
          double newHeight = resizeStart!.height;
          double newX = positionStart!.dx;
          double newY = positionStart!.dy;

          switch (activeHandle!) {
            case ResizeHandle.topLeft:
              newWidth = math.max(20, resizeStart!.width - details.delta.dx);
              newHeight = math.max(20, resizeStart!.height - details.delta.dy);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.topRight:
              newWidth = math.max(20, resizeStart!.width + details.delta.dx);
              newHeight = math.max(20, resizeStart!.height - details.delta.dy);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.bottomLeft:
              newWidth = math.max(20, resizeStart!.width - details.delta.dx);
              newHeight = math.max(20, resizeStart!.height + details.delta.dy);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              break;
            case ResizeHandle.bottomRight:
              newWidth = math.max(20, resizeStart!.width + details.delta.dx);
              newHeight = math.max(20, resizeStart!.height + details.delta.dy);
              break;
            case ResizeHandle.top:
              newHeight = math.max(20, resizeStart!.height - details.delta.dy);
              newY = positionStart!.dy + (resizeStart!.height - newHeight);
              break;
            case ResizeHandle.bottom:
              newHeight = math.max(20, resizeStart!.height + details.delta.dy);
              break;
            case ResizeHandle.left:
              newWidth = math.max(20, resizeStart!.width - details.delta.dx);
              newX = positionStart!.dx + (resizeStart!.width - newWidth);
              break;
            case ResizeHandle.right:
              newWidth = math.max(20, resizeStart!.width + details.delta.dx);
              break;
            default:
              break;
          }

          ref
              .read(presentationProvider.notifier)
              .updateComponent(
                widget.component.id,
                widget.component.copyWith(
                  size: Size(newWidth, newHeight),
                  position: Offset(newX, newY),
                ),
              );
        },
        onPanEnd: (_) {
          activeHandle = null;
          resizeStart = null;
          positionStart = null;
          ref
              .read(historyProvider.notifier)
              .addState(ref.read(presentationProvider));
        },
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return Positioned(
      top: -35,
      left: widget.component.size.width / 2 - 15,
      child: GestureDetector(
        onPanStart: (details) {
          rotationStart = widget.component.rotation;
        },
        onPanUpdate: (details) {
          if (rotationStart == null) return;

          final center = Offset(
            widget.component.size.width / 2,
            widget.component.size.height / 2 + 35,
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
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final Color color;

  LinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) => oldDelegate.color != color;
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class SlidePanel extends ConsumerWidget {
  const SlidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(presentationProvider.notifier).addSlide(),
              icon: const Icon(Icons.add),
              label: const Text('New Slide'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: presentation.slides.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(presentationProvider.notifier)
                  .reorderSlides(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final slide = presentation.slides[index];
              final isSelected = index == presentation.currentSlideIndex;
              return Card(
                key: ValueKey(slide.id),
                color: isSelected ? Colors.blue[100] : null,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: isSelected ? 4 : 1,
                child: InkWell(
                  onTap: () => ref
                      .read(presentationProvider.notifier)
                      .setCurrentSlide(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slide.title ?? 'Slide ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.content_copy, size: 18),
                                      SizedBox(width: 8),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => ref
                                        .read(presentationProvider.notifier)
                                        .duplicateSlide(index),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => ref
                                        .read(presentationProvider.notifier)
                                        .deleteSlide(index),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        height: 60,
                        decoration: BoxDecoration(
                          color: slide.backgroundColor,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${slide.components.length} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedComponentProvider);
    final presentation = ref.watch(presentationProvider);

    if (selectedId == null) {
      return _buildSlideProperties(context, ref, presentation);
    }

    final component = presentation
        .slides[presentation.currentSlideIndex]
        .components
        .firstWhere((c) => c.id == selectedId);

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Properties',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            _buildPropertyCard('Transform', [
              _buildPropertyRow('Type', component.type.name.toUpperCase()),
              _buildPropertySlider(
                'X Position',
                component.position.dx,
                0,
                1000,
                (value) {
                  ref
                      .read(presentationProvider.notifier)
                      .updateComponent(
                        component.id,
                        component.copyWith(
                          position: Offset(value, component.position.dy),
                        ),
                      );
                },
              ),
              _buildPropertySlider(
                'Y Position',
                component.position.dy,
                0,
                600,
                (value) {
                  ref
                      .read(presentationProvider.notifier)
                      .updateComponent(
                        component.id,
                        component.copyWith(
                          position: Offset(component.position.dx, value),
                        ),
                      );
                },
              ),
              _buildPropertySlider('Width', component.size.width, 20, 1000, (
                value,
              ) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(
                        size: Size(value, component.size.height),
                      ),
                    );
              }),
              _buildPropertySlider('Height', component.size.height, 20, 600, (
                value,
              ) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(
                        size: Size(component.size.width, value),
                      ),
                    );
              }),
              _buildPropertySlider('Rotation', component.rotation, -180, 180, (
                value,
              ) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(rotation: value),
                    );
              }, suffix: '°'),
            ]),

            const SizedBox(height: 16),

            if (component.type == ComponentType.text) ...[
              _buildPropertyCard('Text Style', [
                ElevatedButton.icon(
                  onPressed: () => _showFontSizePicker(context, ref, component),
                  icon: const Icon(Icons.format_size, size: 18),
                  label: Text(
                    'Font Size: ${component.textStyle?.fontSize?.toInt() ?? 16}',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showColorPicker(context, ref, component, true),
                  icon: Icon(
                    Icons.color_lens,
                    size: 18,
                    color: component.textStyle?.color ?? Colors.black,
                  ),
                  label: const Text('Text Color'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TextAlign>(
                  segments: const [
                    ButtonSegment(
                      value: TextAlign.left,
                      icon: Icon(Icons.format_align_left, size: 18),
                    ),
                    ButtonSegment(
                      value: TextAlign.center,
                      icon: Icon(Icons.format_align_center, size: 18),
                    ),
                    ButtonSegment(
                      value: TextAlign.right,
                      icon: Icon(Icons.format_align_right, size: 18),
                    ),
                  ],
                  selected: {component.textAlign},
                  onSelectionChanged: (Set<TextAlign> selected) {
                    ref
                        .read(presentationProvider.notifier)
                        .updateComponent(
                          component.id,
                          component.copyWith(textAlign: selected.first),
                        );
                    ref
                        .read(historyProvider.notifier)
                        .addState(ref.read(presentationProvider));
                  },
                ),
              ]),
              const SizedBox(height: 16),
            ],

            if (component.type == ComponentType.shape ||
                component.type == ComponentType.circle ||
                component.type == ComponentType.triangle ||
                component.type == ComponentType.text) ...[
              _buildPropertyCard('Appearance', [
                ElevatedButton.icon(
                  onPressed: () =>
                      _showColorPicker(context, ref, component, false),
                  icon: Icon(
                    Icons.palette,
                    size: 18,
                    color: component.backgroundColor ?? Colors.transparent,
                  ),
                  label: const Text('Background Color'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            _buildPropertyCard('Effects', [
              _buildPropertySlider('Opacity', component.opacity, 0, 1, (value) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(opacity: value),
                    );
              }),
              const SizedBox(height: 8),
              const Text(
                'Animation',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AnimationType>(
                value: component.animation,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: AnimationType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(presentationProvider.notifier)
                        .updateComponent(
                          component.id,
                          component.copyWith(animation: value),
                        );
                    ref
                        .read(historyProvider.notifier)
                        .addState(ref.read(presentationProvider));
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideProperties(
    BuildContext context,
    WidgetRef ref,
    Presentation presentation,
  ) {
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final showGrid = ref.watch(showGridProvider);
    final snapToGrid = ref.watch(snapToGridProvider);

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.slideshow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Slide Properties',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Slide Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: currentSlide.title),
            onSubmitted: (value) {
              ref.read(presentationProvider.notifier).setSlideTitle(value);
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
            },
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _showSlideColorPicker(context, ref),
            icon: Icon(Icons.format_paint, color: currentSlide.backgroundColor),
            label: const Text('Change Background'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'View Options',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Show Grid'),
            value: showGrid,
            onChanged: (value) {
              ref.read(showGridProvider.notifier).state = value;
            },
          ),

          SwitchListTile(
            title: const Text('Snap to Grid'),
            value: snapToGrid,
            onChanged: (value) {
              ref.read(snapToGridProvider.notifier).state = value;
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Components: ${currentSlide.components.length}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Slide ${presentation.currentSlideIndex + 1} of ${presentation.slides.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPropertySlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            Text(
              '${value.toInt()}$suffix',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    PresentationComponent component,
    bool isTextColor,
  ) async {
    Color pickerColor = isTextColor
        ? (component.textStyle?.color ?? Colors.black)
        : (component.backgroundColor ?? Colors.blue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTextColor ? 'Pick Text Color' : 'Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isTextColor) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(
                        textStyle: (component.textStyle ?? GoogleFonts.roboto())
                            .copyWith(color: pickerColor),
                      ),
                    );
              } else {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(backgroundColor: pickerColor),
                    );
              }
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSlideColorPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final presentation = ref.read(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    Color pickerColor = currentSlide.backgroundColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Slide Background'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.accent: false,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(presentationProvider.notifier)
                  .setSlideBackground(pickerColor);
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFontSizePicker(
    BuildContext context,
    WidgetRef ref,
    PresentationComponent component,
  ) async {
    double fontSize = component.textStyle?.fontSize ?? 16;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Size: ${fontSize.toInt()}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Slider(
                value: fontSize,
                min: 8,
                max: 96,
                divisions: 88,
                label: fontSize.toInt().toString(),
                onChanged: (value) => setState(() => fontSize = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(presentationProvider.notifier)
                  .updateComponent(
                    component.id,
                    component.copyWith(
                      textStyle: (component.textStyle ?? GoogleFonts.roboto())
                          .copyWith(fontSize: fontSize),
                    ),
                  );
              ref
                  .read(historyProvider.notifier)
                  .addState(ref.read(presentationProvider));
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class PresenterView extends ConsumerWidget {
  const PresenterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.pageDown) {
              if (presentation.currentSlideIndex <
                  presentation.slides.length - 1) {
                ref
                    .read(presentationProvider.notifier)
                    .setCurrentSlide(presentation.currentSlideIndex + 1);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              if (presentation.currentSlideIndex > 0) {
                ref
                    .read(presentationProvider.notifier)
                    .setCurrentSlide(presentation.currentSlideIndex - 1);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.f5) {
              ref.read(presenterModeProvider.notifier).state = false;
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(currentSlide.id),
                    color: currentSlide.backgroundColor,
                    child: Stack(
                      children:
                          currentSlide.components
                              .map((c) => _buildAnimatedComponent(c))
                              .toList()
                            ..sort((a, b) {
                              final aComp = currentSlide.components.firstWhere(
                                (c) => (a.key as ValueKey).value == c.id,
                              );
                              final bComp = currentSlide.components.firstWhere(
                                (c) => (b.key as ValueKey).value == c.id,
                              );
                              return aComp.zIndex.compareTo(bComp.zIndex);
                            }),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Slide ${presentation.currentSlideIndex + 1} / ${presentation.slides.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 36),
                onPressed: () {
                  ref.read(presenterModeProvider.notifier).state = false;
                },
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Press ESC to exit • Arrow keys to navigate',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedComponent(PresentationComponent component) {
    Widget content = Positioned(
      left: component.position.dx,
      top: component.position.dy,
      child: Transform.rotate(
        angle: component.rotation * math.pi / 180,
        child: Opacity(
          opacity: component.opacity,
          child: Container(
            width: component.size.width,
            height: component.size.height,
            decoration: BoxDecoration(
              color: component.backgroundColor,
              border: component.border != null
                  ? Border.fromBorderSide(component.border!)
                  : null,
            ),
            child: _buildComponentContent(component),
          ),
        ),
      ),
    );

    return AnimatedComponentWrapper(
      key: ValueKey(component.id),
      animation: component.animation,
      child: content,
    );
  }

  Widget _buildComponentContent(PresentationComponent component) {
    switch (component.type) {
      case ComponentType.text:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            component.text ?? '',
            style: component.textStyle,
            textAlign: component.textAlign,
          ),
        );
      case ComponentType.image:
        return component.imageData != null
            ? Image.memory(component.imageData!, fit: BoxFit.contain)
            : const Icon(Icons.image);
      case ComponentType.shape:
        return Container(color: component.backgroundColor);
      case ComponentType.circle:
        return Container(
          decoration: BoxDecoration(
            color: component.backgroundColor,
            shape: BoxShape.circle,
          ),
        );
      case ComponentType.triangle:
        return CustomPaint(
          painter: TrianglePainter(component.backgroundColor ?? Colors.blue),
        );
      case ComponentType.line:
        return CustomPaint(
          painter: LinePainter(component.backgroundColor ?? Colors.black),
        );
    }
  }
}

class AnimatedComponentWrapper extends StatefulWidget {
  final AnimationType animation;
  final Widget child;

  const AnimatedComponentWrapper({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  State<AnimatedComponentWrapper> createState() =>
      _AnimatedComponentWrapperState();
}

class _AnimatedComponentWrapperState extends State<AnimatedComponentWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    switch (widget.animation) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
        break;
      case AnimationType.zoom:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        );
        break;
      case AnimationType.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
      default:
        _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animation == AnimationType.none) {
      return widget.child;
    }

    if (widget.animation == AnimationType.fadeIn) {
      return FadeTransition(opacity: _animation, child: widget.child);
    }

    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
