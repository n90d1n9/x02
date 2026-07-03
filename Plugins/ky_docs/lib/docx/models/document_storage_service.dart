import 'dart:convert';
import 'dart:async';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'document_metadata.dart';
import 'folder.dart';
import 'document_version.dart';

class DocumentStorageService {
  static const String _boxName = 'documents';
  static const String _metadataBoxName = 'metadata';
  static const String _versionsBoxName = 'versions';
  static const String _foldersBoxName = 'folders';
  Box<String>? _documentsBox;
  Box<String>? _metadataBox;
  Box<String>? _versionsBox;
  Box<String>? _foldersBox;
  Future<void> initialize() async {
    await Hive.initFlutter();
    _documentsBox = await Hive.openBox<String>(_boxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
    _versionsBox = await Hive.openBox<String>(_versionsBoxName);
    _foldersBox = await Hive.openBox<String>(_foldersBoxName);
  }

  Future<void> saveDocument(
    String id,
    String content,
    DocumentMetadata metadata,
  ) async {
    if (_documentsBox == null || _metadataBox == null) {
      await initialize();
    }
    await _documentsBox!.put(id, content);
    await _metadataBox!.put(id, jsonEncode(metadata.toJson()));
  }

  Future<String?> loadDocument(String id) async {
    if (_documentsBox == null) await initialize();
    return _documentsBox!.get(id);
  }

  Future<DocumentMetadata?> loadMetadata(String id) async {
    if (_metadataBox == null) await initialize();
    final json = _metadataBox!.get(id);
    if (json == null) return null;
    return DocumentMetadata.fromJson(jsonDecode(json));
  }

  Future<List<DocumentMetadata>> getAllDocuments() async {
    if (_metadataBox == null) await initialize();
    final List<DocumentMetadata> documents = [];
    for (final key in _metadataBox!.keys) {
      final json = _metadataBox!.get(key);
      if (json != null) {
        documents.add(DocumentMetadata.fromJson(jsonDecode(json)));
      }
    }
    documents.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return documents;
  }

  Future<List<DocumentMetadata>> searchDocuments(String query) async {
    if (_documentsBox == null || _metadataBox == null) await initialize();
    final List<DocumentMetadata> results = [];
    final lowercaseQuery = query.toLowerCase();
    for (final key in _metadataBox!.keys) {
      final metaJson = _metadataBox!.get(key);
      final contentJson = _documentsBox!.get(key);
      if (metaJson != null && contentJson != null) {
        final metadata = DocumentMetadata.fromJson(jsonDecode(metaJson));
        if (metadata.title.toLowerCase().contains(lowercaseQuery)) {
          results.add(metadata);
          continue;
        }
        if (metadata.tags.any(
          (tag) => tag.toLowerCase().contains(lowercaseQuery),
        )) {
          results.add(metadata);
          continue;
        }
        try {
          // final delta = quill.Document.fromJson(jsonDecode(contentJson));
          final document = quill.Document.fromJson(jsonDecode(contentJson));
          // final document = quill.Document.fromDelta(delta);
          final plainText = document.toPlainText().toLowerCase();
          if (plainText.contains(lowercaseQuery)) {
            results.add(metadata);
          }
        } catch (e) {
          // Ignore malformed document payloads while collecting search results.
        }
      }
    }
    results.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return results;
  }

  Future<void> deleteDocument(String id) async {
    if (_documentsBox == null || _metadataBox == null) await initialize();
    await _documentsBox!.delete(id);
    await _metadataBox!.delete(id);
    await _versionsBox!.delete(id);
  }

  Future<void> saveVersions(
    String documentId,
    List<DocumentVersion> versions,
  ) async {
    if (_versionsBox == null) await initialize();
    final json = jsonEncode(versions.map((v) => v.toJson()).toList());
    await _versionsBox!.put(documentId, json);
  }

  Future<List<DocumentVersion>> loadVersions(String documentId) async {
    if (_versionsBox == null) await initialize();
    final json = _versionsBox!.get(documentId);
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((v) => DocumentVersion.fromJson(v)).toList();
  }

  Future<void> saveFolder(Folder folder) async {
    if (_foldersBox == null) await initialize();
    await _foldersBox!.put(folder.id, jsonEncode(folder.toJson()));
  }

  Future<List<Folder>> getAllFolders() async {
    if (_foldersBox == null) await initialize();
    final List<Folder> folders = [];
    for (final key in _foldersBox!.keys) {
      final json = _foldersBox!.get(key);
      if (json != null) {
        folders.add(Folder.fromJson(jsonDecode(json)));
      }
    }
    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  Future<void> deleteFolder(String id) async {
    if (_foldersBox == null) await initialize();
    await _foldersBox!.delete(id);
  }
}
