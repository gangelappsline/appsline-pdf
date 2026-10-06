import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Visor de PDF con zoom, desplazamiento continuo, búsqueda de texto
/// e indicador de página.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.title, required this.filePath});

  final String title;
  final String filePath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();

  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _searching = false;
  bool _failed = false;
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void dispose() {
    _searchResult.removeListener(_onSearchResultChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {});
  }

  void _startSearch(String query) {
    final String text = query.trim();
    if (text.isEmpty) return;
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult = _controller.searchText(text);
    _searchResult.addListener(_onSearchResultChanged);
  }

  void _closeSearch() {
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.clear();
    _searchController.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSearch,
                tooltip: 'Cerrar búsqueda',
              )
            : null,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar en el documento…',
                  border: InputBorder.none,
                ),
                onSubmitted: _startSearch,
              )
            : Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          if (_searching && _searchResult.hasResult) ...<Widget>[
            Center(
              child: Text(
                '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: _searchResult.previousInstance,
              tooltip: 'Anterior',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: _searchResult.nextInstance,
              tooltip: 'Siguiente',
            ),
          ] else if (!_searching && !_failed)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
              tooltip: 'Buscar',
            ),
        ],
      ),
      body: _failed ? _buildError(theme) : _buildViewer(),
      bottomNavigationBar: _pageCount > 0 && !_failed
          ? SafeArea(
              child: Container(
                height: 36,
                alignment: Alignment.center,
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildViewer() {
    return SfPdfViewer.file(
      File(widget.filePath),
      controller: _controller,
      canShowScrollHead: true,
      canShowPaginationDialog: true,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() => _pageCount = details.document.pages.count);
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() => _currentPage = details.newPageNumber);
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() => _failed = true);
      },
    );
  }

  Widget _buildError(ThemeData theme) {
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
              'No se pudo abrir el PDF.\nPuede estar dañado o protegido.',
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
