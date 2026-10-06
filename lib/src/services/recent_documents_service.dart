import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recent_document.dart';

/// Gestiona la lista de documentos recientes y su copia local.
///
/// Los archivos elegidos con el selector se copian al directorio de
/// documentos de la app (`<documents>/docs/`) para que sigan disponibles
/// aunque el origen desaparezca (en iOS el picker entrega copias temporales).
class RecentDocumentsService {
  static const String _prefsKey = 'recent_documents_v1';
  static const int _maxRecents = 30;

  Future<Directory> _docsDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}${Platform.pathSeparator}docs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ruta absoluta de un documento gestionado por la app.
  Future<String> absolutePathFor(RecentDocument doc) async {
    final Directory dir = await _docsDir();
    return '${dir.path}${Platform.pathSeparator}${doc.fileName}';
  }

  Future<List<RecentDocument>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return <RecentDocument>[];
    }
    final List<RecentDocument> docs = RecentDocument.decodeList(raw);
    docs.sort((RecentDocument a, RecentDocument b) => b.openedAt.compareTo(a.openedAt));
    return docs;
  }

  Future<void> _save(List<RecentDocument> docs) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, RecentDocument.encodeList(docs));
  }

  /// Copia [sourcePath] al almacenamiento de la app y lo registra en recientes.
  Future<RecentDocument> register({
    required String sourcePath,
    required String displayName,
    required DocumentType type,
  }) async {
    final Directory dir = await _docsDir();
    final File source = File(sourcePath);

    final String safeName = _uniqueFileName(displayName);
    final File target = File('${dir.path}${Platform.pathSeparator}$safeName');

    // Si el archivo ya está dentro del directorio gestionado, no se copia.
    final bool alreadyManaged = source.path.startsWith(dir.path);
    final File stored = alreadyManaged ? source : await source.copy(target.path);

    final RecentDocument doc = RecentDocument(
      fileName: stored.uri.pathSegments.last,
      displayName: displayName,
      type: type,
      sizeInBytes: await stored.length(),
      openedAt: DateTime.now(),
    );

    final List<RecentDocument> docs = await load();
    // Evita duplicados por nombre visible: conserva la entrada más reciente.
    docs.removeWhere((RecentDocument d) => d.displayName == doc.displayName);
    docs.insert(0, doc);

    // Limita la lista y borra las copias locales que salen de ella.
    while (docs.length > _maxRecents) {
      final RecentDocument removed = docs.removeLast();
      await _deleteStoredFile(removed);
    }
    await _save(docs);
    return doc;
  }

  /// Marca un documento como abierto ahora (lo sube al inicio de la lista).
  Future<void> touch(RecentDocument doc) async {
    final List<RecentDocument> docs = await load();
    docs.removeWhere((RecentDocument d) => d.fileName == doc.fileName);
    docs.insert(0, doc.copyWith(openedAt: DateTime.now()));
    await _save(docs);
  }

  Future<void> remove(RecentDocument doc) async {
    final List<RecentDocument> docs = await load();
    docs.removeWhere((RecentDocument d) => d.fileName == doc.fileName);
    await _save(docs);
    await _deleteStoredFile(doc);
  }

  Future<void> _deleteStoredFile(RecentDocument doc) async {
    try {
      final File file = File(await absolutePathFor(doc));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignorado: borrar la copia local es "best effort".
    }
  }

  String _uniqueFileName(String displayName) {
    final String stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final String sanitized = displayName.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    return '${stamp}_$sanitized';
  }
}
