import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/recent_document.dart';
import '../services/recent_documents_service.dart';
import '../widgets/recent_document_tile.dart';
import 'docx_viewer_screen.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecentDocumentsService _recents = RecentDocumentsService();

  List<RecentDocument> _documents = <RecentDocument>[];
  bool _loading = true;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final List<RecentDocument> docs = await _recents.load();
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  Future<void> _pickDocument() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'docx'],
      );
      final String? path = result?.files.single.path;
      final String? name = result?.files.single.name;
      if (path == null || name == null) return; // Cancelado por el usuario.

      final DocumentType? type = _typeFromName(name);
      if (type == null) {
        _showMessage('Solo se admiten archivos PDF y DOCX.');
        return;
      }

      final RecentDocument doc = await _recents.register(
        sourcePath: path,
        displayName: name,
        type: type,
      );
      await _loadRecents();
      await _openDocument(doc, touch: false);
    } catch (_) {
      _showMessage('No se pudo abrir el archivo seleccionado.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  DocumentType? _typeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return DocumentType.pdf;
    if (lower.endsWith('.docx')) return DocumentType.docx;
    return null;
  }

  Future<void> _openDocument(RecentDocument doc, {bool touch = true}) async {
    final String path = await _recents.absolutePathFor(doc);
    if (touch) {
      await _recents.touch(doc);
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => doc.type == DocumentType.pdf
            ? PdfViewerScreen(title: doc.displayName, filePath: path)
            : DocxViewerScreen(title: doc.displayName, filePath: path),
      ),
    );
    await _loadRecents();
  }

  Future<void> _removeDocument(RecentDocument doc) async {
    await _recents.remove(doc);
    await _loadRecents();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 32),
              Text(
                'Documentos',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF y Word (.docx)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _picking ? null : _pickDocument,
                icon: _picking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 20),
                label: const Text('Abrir documento'),
              ),
              const SizedBox(height: 32),
              if (_documents.isNotEmpty)
                Text(
                  'RECIENTES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.description_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no has abierto documentos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _documents.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        final RecentDocument doc = _documents[index];
        return RecentDocumentTile(
          document: doc,
          onTap: () => _openDocument(doc),
          onDelete: () => _removeDocument(doc),
        );
      },
    );
  }
}
