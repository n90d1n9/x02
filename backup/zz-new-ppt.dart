// pubspec.yaml dependencies:
// flutter_riverpod: ^2.4.9
// riverpod_annotation: ^2.3.3
// freezed_annotation: ^2.4.1
// uuid: ^4.2.2
// file_picker: ^6.1.1
// path_provider: ^2.1.1
// archive: ^3.4.9
// xml: ^6.4.2
// image: ^4.1.3
// flex_color_picker: ^3.3.0

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

// ==================== MODELS ====================

enum ComponentType { text, image, shape, line }

enum AnimationType { none, fadeIn, slideIn, zoom, bounce }

class PresentationComponent {
  final String id;
  final ComponentType type;
  final Offset position;
  final Size size;
  final String? text;
  final TextStyle? textStyle;
  final Uint8List? imageData;
  final Color? backgroundColor;
  final double rotation;
  final int zIndex;
  final AnimationType animation;
  final double opacity;
  final BorderSide? border;

  PresentationComponent({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.text,
    this.textStyle,
    this.imageData,
    this.backgroundColor,
    this.rotation = 0,
    this.zIndex = 0,
    this.animation = AnimationType.none,
    this.opacity = 1.0,
    this.border,
  });

  PresentationComponent copyWith({
    Offset? position,
    Size? size,
    String? text,
    TextStyle? textStyle,
    Uint8List? imageData,
    Color? backgroundColor,
    double? rotation,
    int? zIndex,
    AnimationType? animation,
    double? opacity,
    BorderSide? border,
  }) {
    return PresentationComponent(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      imageData: imageData ?? this.imageData,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      animation: animation ?? this.animation,
      opacity: opacity ?? this.opacity,
      border: border ?? this.border,
    );
  }
}

class Slide {
  final String id;
  final List<PresentationComponent> components;
  final Color backgroundColor;
  final String? notes;

  Slide({
    required this.id,
    required this.components,
    this.backgroundColor = Colors.white,
    this.notes,
  });

  Slide copyWith({
    List<PresentationComponent>? components,
    Color? backgroundColor,
    String? notes,
  }) {
    return Slide(
      id: id,
      components: components ?? this.components,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      notes: notes ?? this.notes,
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
          slides: [Slide(id: const Uuid().v4(), components: [])],
        ),
      );

  void addSlide() {
    state = state.copyWith(
      slides: [
        ...state.slides,
        Slide(id: const Uuid().v4(), components: []),
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

  void loadPresentation(Presentation presentation) {
    state = presentation;
  }
}

final selectedComponentProvider = StateProvider<String?>((ref) => null);
final presenterModeProvider = StateProvider<bool>((ref) => false);

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
    // Remove any states after current index
    if (currentIndex < state.length - 1) {
      state = state.sublist(0, currentIndex + 1);
    }

    // Add new state
    state = [...state, HistoryState(presentation, DateTime.now())];
    currentIndex++;

    // Keep only last 50 states
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

// ==================== PPT EXPORT/IMPORT SERVICE ====================

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
      } else if (component.type == ComponentType.shape) {
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
              <a:t>${component.text ?? ''}</a:t>
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
          <a:prstGeom prst="rect">
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

  static Future<Presentation> importFromPpt(String filePath) async {
    final presentation = Presentation(
      id: const Uuid().v4(),
      title: 'Imported Presentation',
      slides: [Slide(id: const Uuid().v4(), components: [])],
    );
    return presentation;
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
      title: 'Advanced Presentation',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
      return PresenterView();
    }

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete) {
            final selected = ref.read(selectedComponentProvider);
            if (selected != null) {
              ref.read(presentationProvider.notifier).deleteComponent(selected);
              ref.read(selectedComponentProvider.notifier).state = null;
            }
          } else if (HardwareKeyboard.instance.isControlPressed) {
            if (event.logicalKey == LogicalKeyboardKey.keyZ) {
              ref.read(historyProvider.notifier).undo();
            } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
              ref.read(historyProvider.notifier).redo();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(presentation.title),
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
              tooltip: 'Presenter Mode',
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
          ],
        ),
        body: Row(
          children: [
            SizedBox(width: 200, child: SlidePanel()),
            Expanded(
              child: Column(
                children: [
                  Toolbar(),
                  Expanded(child: SlideCanvas()),
                ],
              ),
            ),
            SizedBox(width: 280, child: PropertiesPanel()),
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
      final presentation = await PptService.importFromPpt(
        result.files.single.path!,
      );
      ref.read(presentationProvider.notifier).loadPresentation(presentation);
    }
  }
}

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Add Text Box',
            onPressed: () => _addTextBox(ref),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Add Image',
            onPressed: () => _addImage(ref),
          ),
          IconButton(
            icon: const Icon(Icons.crop_square),
            tooltip: 'Add Shape',
            onPressed: () => _addShape(ref),
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.flip_to_front),
            tooltip: 'Bring to Front',
            onPressed: () {
              final selected = ref.read(selectedComponentProvider);
              if (selected != null) {
                ref.read(presentationProvider.notifier).bringToFront(selected);
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
              }
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete (Del)',
            onPressed: () => _deleteSelected(ref),
          ),
        ],
      ),
    );
  }

  void _addTextBox(WidgetRef ref) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.text,
      position: const Offset(100, 100),
      size: const Size(200, 100),
      text: 'New Text',
      textStyle: const TextStyle(fontSize: 24, color: Colors.black),
      backgroundColor: Colors.transparent,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
  }

  Future<void> _addImage(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      final component = PresentationComponent(
        id: const Uuid().v4(),
        type: ComponentType.image,
        position: const Offset(100, 100),
        size: const Size(300, 200),
        imageData: result.files.single.bytes,
      );
      ref.read(presentationProvider.notifier).addComponent(component);
      ref
          .read(historyProvider.notifier)
          .addState(ref.read(presentationProvider));
    }
  }

  void _addShape(WidgetRef ref) {
    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.shape,
      position: const Offset(100, 100),
      size: const Size(150, 150),
      backgroundColor: Colors.blue,
    );
    ref.read(presentationProvider.notifier).addComponent(component);
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
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

class SlideCanvas extends ConsumerWidget {
  const SlideCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final sortedComponents = List<PresentationComponent>.from(
      currentSlide.components,
    )..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Container(
      color: Colors.grey[300],
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: () {
              ref.read(selectedComponentProvider.notifier).state = null;
            },
            child: Container(
              color: currentSlide.backgroundColor,
              child: Stack(
                children: sortedComponents
                    .map((c) => ResizableComponent(component: c))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    final isSelected =
        ref.watch(selectedComponentProvider) == widget.component.id;

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
          onPanStart: (details) {
            if (!isSelected) return;
            dragStart = details.localPosition;
            positionStart = widget.component.position;
          },
          onPanUpdate: (details) {
            if (!isSelected || dragStart == null || positionStart == null)
              return;
            final delta = details.localPosition - dragStart!;
            final newPosition = positionStart! + delta;
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
        return TextField(
          controller: TextEditingController(text: widget.component.text),
          style: widget.component.textStyle,
          maxLines: null,
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
        );
      case ComponentType.image:
        return widget.component.imageData != null
            ? Image.memory(widget.component.imageData!, fit: BoxFit.contain)
            : const Icon(Icons.image);
      case ComponentType.shape:
        return Container(color: widget.component.backgroundColor);
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
              newWidth = resizeStart!.width - details.delta.dx;
              newHeight = resizeStart!.height - details.delta.dy;
              newX = positionStart!.dx + details.delta.dx;
              newY = positionStart!.dy + details.delta.dy;
              break;
            case ResizeHandle.topRight:
              newWidth = resizeStart!.width + details.delta.dx;
              newHeight = resizeStart!.height - details.delta.dy;
              newY = positionStart!.dy + details.delta.dy;
              break;
            case ResizeHandle.bottomLeft:
              newWidth = resizeStart!.width - details.delta.dx;
              newHeight = resizeStart!.height + details.delta.dy;
              newX = positionStart!.dx + details.delta.dx;
              break;
            case ResizeHandle.bottomRight:
              newWidth = resizeStart!.width + details.delta.dx;
              newHeight = resizeStart!.height + details.delta.dy;
              break;
            case ResizeHandle.top:
              newHeight = resizeStart!.height - details.delta.dy;
              newY = positionStart!.dy + details.delta.dy;
              break;
            case ResizeHandle.bottom:
              newHeight = resizeStart!.height + details.delta.dy;
              break;
            case ResizeHandle.left:
              newWidth = resizeStart!.width - details.delta.dx;
              newX = positionStart!.dx + details.delta.dx;
              break;
            case ResizeHandle.right:
              newWidth = resizeStart!.width + details.delta.dx;
              break;
            default:
              break;
          }

          if (newWidth > 20 && newHeight > 20) {
            ref
                .read(presentationProvider.notifier)
                .updateComponent(
                  widget.component.id,
                  widget.component.copyWith(
                    size: Size(newWidth, newHeight),
                    position: Offset(newX, newY),
                  ),
                );
          }
        },
        onPanEnd: (_) {
          activeHandle = null;
          ref
              .read(historyProvider.notifier)
              .addState(ref.read(presentationProvider));
        },
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return Positioned(
      top: -30,
      left: widget.component.size.width / 2 - 12,
      child: GestureDetector(
        onPanStart: (details) {
          rotationStart = widget.component.rotation;
        },
        onPanUpdate: (details) {
          if (rotationStart == null) return;

          final center = Offset(
            widget.component.size.width / 2,
            widget.component.size.height / 2,
          );

          final angle = math.atan2(
            details.localPosition.dy - center.dy,
            details.localPosition.dx - center.dx,
          );

          final rotation = angle * 180 / math.pi;

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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 16),
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

class SlidePanel extends ConsumerWidget {
  const SlidePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(presentationProvider.notifier).addSlide(),
              icon: const Icon(Icons.add),
              label: const Text('New Slide'),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: presentation.slides.length,
              onReorder: (oldIndex, newIndex) {
                // Implement slide reordering
              },
              itemBuilder: (context, index) {
                final isSelected = index == presentation.currentSlideIndex;
                return Card(
                  key: ValueKey(presentation.slides[index].id),
                  color: isSelected ? Colors.blue[100] : null,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text('Slide ${index + 1}'),
                    subtitle: Text(
                      '${presentation.slides[index].components.length} items',
                    ),
                    onTap: () => ref
                        .read(presentationProvider.notifier)
                        .setCurrentSlide(index),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Duplicate'),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => ref
                                .read(presentationProvider.notifier)
                                .duplicateSlide(index),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => ref
                                .read(presentationProvider.notifier)
                                .deleteSlide(index),
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
      ),
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
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Component Properties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),

            _buildPropertyRow('Type', component.type.name.toUpperCase()),
            _buildPropertyRow('X', '${component.position.dx.toInt()}px'),
            _buildPropertyRow('Y', '${component.position.dy.toInt()}px'),
            _buildPropertyRow('Width', '${component.size.width.toInt()}px'),
            _buildPropertyRow('Height', '${component.size.height.toInt()}px'),
            _buildPropertyRow('Rotation', '${component.rotation.toInt()}°'),
            _buildPropertyRow('Z-Index', component.zIndex.toString()),

            const SizedBox(height: 16),

            if (component.type == ComponentType.text) ...[
              const Text(
                'Text Style',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showFontSizePicker(context, ref, component),
                child: Text(
                  'Font Size: ${component.textStyle?.fontSize?.toInt() ?? 16}',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    _showColorPicker(context, ref, component, true),
                child: const Text('Text Color'),
              ),
            ],

            if (component.type == ComponentType.shape ||
                component.type == ComponentType.text) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    _showColorPicker(context, ref, component, false),
                child: const Text('Background Color'),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Opacity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: component.opacity,
              onChanged: (value) {
                ref
                    .read(presentationProvider.notifier)
                    .updateComponent(
                      component.id,
                      component.copyWith(opacity: value),
                    );
              },
              onChangeEnd: (_) {
                ref
                    .read(historyProvider.notifier)
                    .addState(ref.read(presentationProvider));
              },
            ),

            const SizedBox(height: 16),
            const Text(
              'Animation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<AnimationType>(
              value: component.animation,
              isExpanded: true,
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

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slide Properties',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showSlideColorPicker(context, ref),
            child: const Text('Change Background'),
          ),
          const SizedBox(height: 16),
          Text('Components: ${currentSlide.components.length}'),
          const SizedBox(height: 8),
          Text(
            'Slide ${presentation.currentSlideIndex + 1} of ${presentation.slides.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
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
                        textStyle: (component.textStyle ?? const TextStyle())
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
              Text('Size: ${fontSize.toInt()}', style: TextStyle(fontSize: 18)),
              Slider(
                value: fontSize,
                min: 8,
                max: 72,
                divisions: 64,
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
                      textStyle: (component.textStyle ?? const TextStyle())
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
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space) {
              if (presentation.currentSlideIndex <
                  presentation.slides.length - 1) {
                ref
                    .read(presentationProvider.notifier)
                    .setCurrentSlide(presentation.currentSlideIndex + 1);
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (presentation.currentSlideIndex > 0) {
                ref
                    .read(presentationProvider.notifier)
                    .setCurrentSlide(presentation.currentSlideIndex - 1);
              }
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              ref.read(presenterModeProvider.notifier).state = false;
            }
          }
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedSlideTransition(
                  key: ValueKey(currentSlide.id),
                  child: Container(
                    color: currentSlide.backgroundColor,
                    child: Stack(
                      children:
                          currentSlide.components
                              .map((c) => _buildAnimatedComponent(c))
                              .toList()
                            ..sort((a, b) {
                              final aZ = currentSlide.components
                                  .firstWhere(
                                    (c) => (a.key as ValueKey).value == c.id,
                                  )
                                  .zIndex;
                              final bZ = currentSlide.components
                                  .firstWhere(
                                    (c) => (b.key as ValueKey).value == c.id,
                                  )
                                  .zIndex;
                              return aZ.compareTo(bZ);
                            }),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Slide ${presentation.currentSlideIndex + 1} / ${presentation.slides.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () {
                  ref.read(presenterModeProvider.notifier).state = false;
                },
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
          child: Text(component.text ?? '', style: component.textStyle),
        );
      case ComponentType.image:
        return component.imageData != null
            ? Image.memory(component.imageData!, fit: BoxFit.contain)
            : const Icon(Icons.image);
      case ComponentType.shape:
        return Container(color: component.backgroundColor);
      case ComponentType.line:
        return CustomPaint(
          painter: LinePainter(component.backgroundColor ?? Colors.black),
        );
    }
  }
}

class AnimatedSlideTransition extends StatefulWidget {
  final Widget child;

  const AnimatedSlideTransition({super.key, required this.child});

  @override
  State<AnimatedSlideTransition> createState() =>
      _AnimatedSlideTransitionState();
}

class _AnimatedSlideTransitionState extends State<AnimatedSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _slideAnimation, child: widget.child);
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
