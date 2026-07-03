// ppt_reader_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class PowerPointSlide {
  final String id;
  final String title;
  final String content;
  final List<String> bulletPoints;
  final List<PowerPointImage> images;
  final String notes;

  PowerPointSlide({
    required this.id,
    required this.title,
    this.content = '',
    this.bulletPoints = const [],
    this.images = const [],
    this.notes = '',
  });
}

class PowerPointImage {
  final String id;
  final String relationshipId;
  final Uint8List bytes;
  final String contentType;

  PowerPointImage({
    required this.id,
    required this.relationshipId,
    required this.bytes,
    required this.contentType,
  });
}

class PowerPointPresentation {
  final String title;
  final List<PowerPointSlide> slides;
  final Map<String, PowerPointImage> images;

  PowerPointPresentation({
    required this.title,
    required this.slides,
    required this.images,
  });
}

class PowerPointReaderService {
  // Cache directories
  late Directory _tempDir;
  late Directory _extractionDir;

  /// Initialize the service by creating necessary directories
  Future<void> initialize() async {
    _tempDir = await getTemporaryDirectory();
    _extractionDir = Directory('${_tempDir.path}/ppt_extraction');

    // Clear any existing extraction directory
    if (await _extractionDir.exists()) {
      await _extractionDir.delete(recursive: true);
    }
    await _extractionDir.create(recursive: true);
  }

  /// Read a PowerPoint file from a local path
  Future<PowerPointPresentation> readFromFile(File file) async {
    await initialize();

    try {
      // Check file extension
      if (!file.path.toLowerCase().endsWith('.pptx')) {
        throw Exception('Only .pptx files are supported');
      }

      // Extract the PPTX file (which is a ZIP archive)
      final extractionPath =
          '${_extractionDir.path}/${path.basenameWithoutExtension(file.path)}';
      final extractionDir = Directory(extractionPath);

      if (await extractionDir.exists()) {
        await extractionDir.delete(recursive: true);
      }
      await extractionDir.create(recursive: true);

      await ZipFile.extractToDirectory(
        zipFile: file,
        destinationDir: extractionDir,
      );

      // Parse the extracted content
      return await _parseExtractedContent(extractionPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Read a PowerPoint file from a URL
  Future<PowerPointPresentation> readFromUrl(String url) async {
    await initialize();

    try {
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Save to temp file
      final fileName = path.basename(url);
      final tempFile = File('${_tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Process the downloaded file
      return await readFromFile(tempFile);
    } catch (e) {
      rethrow;
    }
  }

  /// Parse the content of an extracted PPTX file
  Future<PowerPointPresentation> _parseExtractedContent(
    String extractionPath,
  ) async {
    try {
      // Read presentation.xml for main presentation metadata
      final presentationXmlPath = '$extractionPath/ppt/presentation.xml';
      final presentationFile = File(presentationXmlPath);

      if (!await presentationFile.exists()) {
        throw Exception(
          'Invalid PowerPoint format: presentation.xml not found',
        );
      }

      final presentationXml = await presentationFile.readAsString();
      final presentationDoc = XmlDocument.parse(presentationXml);

      // Get slide references from presentation.xml
      final slideIds = _getSlideIds(presentationDoc);

      // Parse each slide
      final slides = <PowerPointSlide>[];
      final images = <String, PowerPointImage>{};

      // Process relationships first to map image references
      final relationshipsMap = await _parseRelationships(extractionPath);

      // Process slides
      for (int i = 0; i < slideIds.length; i++) {
        final slideId = slideIds[i];
        final slideNumber = i + 1;

        try {
          final slideXmlPath =
              '$extractionPath/ppt/slides/slide$slideNumber.xml';
          final slideFile = File(slideXmlPath);

          if (await slideFile.exists()) {
            final slideXml = await slideFile.readAsString();
            final slideDoc = XmlDocument.parse(slideXml);

            // Extract slide content
            final slide = await _parseSlide(
              slideDoc,
              slideId,
              slideNumber,
              extractionPath,
              relationshipsMap['slides/slide$slideNumber.xml'] ?? {},
            );

            slides.add(slide);

            // Collect slide images
            for (final image in slide.images) {
              images[image.id] = image;
            }
          }
        } catch (e) {
          debugPrint('Error parsing slide $slideNumber: $e');
          // Continue with next slide
        }
      }

      // Get presentation title from core properties
      String title = 'Untitled Presentation';
      try {
        final corePropsPath = '$extractionPath/docProps/core.xml';
        final corePropsFile = File(corePropsPath);

        if (await corePropsFile.exists()) {
          final corePropsXml = await corePropsFile.readAsString();
          final corePropsDoc = XmlDocument.parse(corePropsXml);

          final titleElement =
              corePropsDoc.findAllElements('dc:title').firstOrNull;
          if (titleElement != null && titleElement.innerText.isNotEmpty) {
            title = titleElement.innerText;
          }
        }
      } catch (e) {
        debugPrint('Error parsing presentation title: $e');
      }

      return PowerPointPresentation(
        title: title,
        slides: slides,
        images: images,
      );
    } catch (e) {
      throw Exception('Failed to parse PowerPoint content: $e');
    }
  }

  /// Get all slide IDs from presentation.xml
  List<String> _getSlideIds(XmlDocument presentationDoc) {
    final slideIds = <String>[];

    try {
      final sldIdLst =
          presentationDoc.findAllElements('p:sldIdLst').firstOrNull;

      if (sldIdLst != null) {
        final sldIds = sldIdLst.findAllElements('p:sldId');

        for (final sldId in sldIds) {
          final id = sldId.getAttribute('id');
          if (id != null) {
            slideIds.add(id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting slide IDs: $e');
    }

    return slideIds;
  }

  /// Parse all relationships from various rels files
  Future<Map<String, Map<String, String>>> _parseRelationships(
    String extractionPath,
  ) async {
    final allRelationships = <String, Map<String, String>>{};

    try {
      // Parse main relationships
      final relsDir = Directory('$extractionPath/_rels');
      if (await relsDir.exists()) {
        await for (final file in relsDir.list()) {
          if (file is File && file.path.endsWith('.rels')) {
            final targetPath = path.basename(file.path).replaceAll('.rels', '');
            allRelationships[targetPath] = await _parseRelationshipFile(file);
          }
        }
      }

      // Parse slide relationships
      final slideRelsDir = Directory('$extractionPath/ppt/slides/_rels');
      if (await slideRelsDir.exists()) {
        await for (final file in slideRelsDir.list()) {
          if (file is File && file.path.endsWith('.rels')) {
            final slideFileName = path
                .basename(file.path)
                .replaceAll('.rels', '');
            allRelationships['slides/$slideFileName'] =
                await _parseRelationshipFile(file);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing relationships: $e');
    }

    return allRelationships;
  }

  /// Parse a single relationship file
  Future<Map<String, String>> _parseRelationshipFile(File file) async {
    final relationships = <String, String>{};

    try {
      final content = await file.readAsString();
      final doc = XmlDocument.parse(content);

      final relationshipElements = doc.findAllElements('Relationship');

      for (final rel in relationshipElements) {
        final id = rel.getAttribute('Id');
        final target = rel.getAttribute('Target');

        if (id != null && target != null) {
          relationships[id] = target;
        }
      }
    } catch (e) {
      debugPrint('Error parsing relationship file ${file.path}: $e');
    }

    return relationships;
  }

  /// Parse a single slide from its XML
  Future<PowerPointSlide> _parseSlide(
    XmlDocument slideDoc,
    String slideId,
    int slideNumber,
    String extractionPath,
    Map<String, String> relationships,
  ) async {
    String title = 'Slide $slideNumber';
    String content = '';
    final bulletPoints = <String>[];
    final slideImages = <PowerPointImage>[];
    String notes = '';

    try {
      // Find title from slide
      final titleElement = slideDoc.findAllElements('p:title').firstOrNull;
      if (titleElement != null) {
        final textElements = titleElement.findAllElements('a:t');
        if (textElements.isNotEmpty) {
          title = textElements.map((e) => e.innerText).join(' ');
        }
      }

      // Extract text content
      final textElements = slideDoc.findAllElements('a:t');
      content = textElements.map((e) => e.innerText).join('\n');

      // Extract bullet points
      final paragraphElements = slideDoc.findAllElements('a:p');
      for (final paragraph in paragraphElements) {
        final pPr = paragraph.findElements('a:pPr').firstOrNull;
        final textInParagraph = paragraph
            .findAllElements('a:t')
            .map((e) => e.innerText)
            .join(' ');

        // Check if it's a bullet point (has bullet properties)
        if (pPr != null &&
            pPr.findElements('a:buChar').isNotEmpty &&
            textInParagraph.isNotEmpty) {
          bulletPoints.add(textInParagraph);
        }
      }

      // Extract images
      final picElements = slideDoc.findAllElements('p:pic');
      for (final pic in picElements) {
        try {
          final nvPicPr = pic.findElements('p:nvPicPr').firstOrNull;
          if (nvPicPr != null) {
            final cNvPr = nvPicPr.findElements('p:cNvPr').firstOrNull;
            if (cNvPr != null) {
              final imageId = cNvPr.getAttribute('id') ?? '';
              final imageName = cNvPr.getAttribute('name') ?? '';

              // Find relationship ID for this image
              final blipFill = pic.findElements('p:blipFill').firstOrNull;
              final blip = blipFill?.findElements('a:blip').firstOrNull;
              final relationshipId = blip?.getAttribute('r:embed') ?? '';

              if (relationshipId.isNotEmpty &&
                  relationships.containsKey(relationshipId)) {
                final imagePath = relationships[relationshipId]!;

                // Load image file
                final imageFilePath =
                    '$extractionPath/ppt/${imagePath.replaceAll('../', '')}';
                final imageFile = File(imageFilePath);

                if (await imageFile.exists()) {
                  final imageBytes = await imageFile.readAsBytes();
                  final contentType = _getContentTypeFromPath(imagePath);

                  slideImages.add(
                    PowerPointImage(
                      id: imageId,
                      relationshipId: relationshipId,
                      bytes: imageBytes,
                      contentType: contentType,
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing image: $e');
        }
      }

      // Try to extract notes
      try {
        final notesPath =
            '$extractionPath/ppt/notesSlides/notesSlide$slideNumber.xml';
        final notesFile = File(notesPath);

        if (await notesFile.exists()) {
          final notesXml = await notesFile.readAsString();
          final notesDoc = XmlDocument.parse(notesXml);

          final noteTextElements = notesDoc.findAllElements('a:t');
          notes = noteTextElements.map((e) => e.innerText).join('\n');
        }
      } catch (e) {
        // Notes are optional, so just log the error
        debugPrint('Error parsing notes for slide $slideNumber: $e');
      }
    } catch (e) {
      debugPrint('Error parsing slide content: $e');
    }

    return PowerPointSlide(
      id: slideId,
      title: title,
      content: content,
      bulletPoints: bulletPoints,
      images: slideImages,
      notes: notes,
    );
  }

  /// Determine content type from file path
  String _getContentTypeFromPath(String path) {
    final extension = path.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  /// Clean up temporary files
  Future<void> cleanup() async {
    try {
      if (await _extractionDir.exists()) {
        await _extractionDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
