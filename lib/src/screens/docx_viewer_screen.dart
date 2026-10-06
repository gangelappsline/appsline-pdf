import 'package:flutter/material.dart';

import '../services/docx_extractor.dart';

/// Visor de DOCX: muestra el texto extraído del documento con
/// tamaño de letra ajustable y texto seleccionable.
class DocxViewerScreen extends StatefulWidget {
  const DocxViewerScreen({super.key, required this.title, required this.filePath});

  final String title;
  final String filePath;

  @override
  State<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends State<DocxViewerScreen> {
  static const double _minFontSize = 12;
  static const double _maxFontSize = 28;

  late Future<String> _textFuture;
  double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    _textFuture = DocxExtractor.extractText(widget.filePath);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _fontSize > _minFontSize ? () => _changeFontSize(-2) : null,
            tooltip: 'Reducir letra',
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: _fontSize < _maxFontSize ? () => _changeFontSize(2) : null,
            tooltip: 'Aumentar letra',
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _textFuture,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError(theme, snapshot.error);
          }
          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: SelectableText(
                snapshot.data!,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object? error) {
    final String message = error is FormatException
        ? error.message
        : 'No se pudo leer el documento.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
