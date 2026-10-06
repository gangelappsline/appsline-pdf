import 'package:flutter/material.dart';

import '../models/recent_document.dart';

/// Fila minimalista de un documento reciente, con borrado por deslizamiento.
class RecentDocumentTile extends StatelessWidget {
  const RecentDocumentTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  final RecentDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPdf = document.type == DocumentType.pdf;

    return Dismissible(
      key: ValueKey<String>(document.fileName),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error.withValues(alpha: 0.9),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPdf ? 'PDF' : 'DOC',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        title: Text(
          document.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_formatSize(document.sizeInBytes)}  ·  ${_formatDate(document.openedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    final int diff = today.difference(day).inDays;

    if (diff == 0) {
      final String h = date.hour.toString().padLeft(2, '0');
      final String m = date.minute.toString().padLeft(2, '0');
      return 'Hoy, $h:$m';
    }
    if (diff == 1) return 'Ayer';
    return '${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}/'
        '${day.year}';
  }
}
