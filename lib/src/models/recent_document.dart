import 'dart:convert';

enum DocumentType { pdf, docx }

/// Documento abierto recientemente. Solo se guarda el nombre del archivo:
/// la ruta absoluta se reconstruye con el directorio de documentos de la app,
/// que puede cambiar entre instalaciones (especialmente en iOS).
class RecentDocument {
  const RecentDocument({
    required this.fileName,
    required this.displayName,
    required this.type,
    required this.sizeInBytes,
    required this.openedAt,
  });

  final String fileName;
  final String displayName;
  final DocumentType type;
  final int sizeInBytes;
  final DateTime openedAt;

  RecentDocument copyWith({DateTime? openedAt}) => RecentDocument(
        fileName: fileName,
        displayName: displayName,
        type: type,
        sizeInBytes: sizeInBytes,
        openedAt: openedAt ?? this.openedAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'fileName': fileName,
        'displayName': displayName,
        'type': type.name,
        'sizeInBytes': sizeInBytes,
        'openedAt': openedAt.toIso8601String(),
      };

  static RecentDocument? fromJson(Map<String, Object?> json) {
    try {
      return RecentDocument(
        fileName: json['fileName']! as String,
        displayName: json['displayName']! as String,
        type: DocumentType.values.byName(json['type']! as String),
        sizeInBytes: (json['sizeInBytes'] as num?)?.toInt() ?? 0,
        openedAt: DateTime.parse(json['openedAt']! as String),
      );
    } catch (_) {
      return null;
    }
  }

  static String encodeList(List<RecentDocument> docs) =>
      jsonEncode(docs.map((RecentDocument d) => d.toJson()).toList());

  static List<RecentDocument> decodeList(String raw) {
    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return data
          .whereType<Map<String, Object?>>()
          .map(RecentDocument.fromJson)
          .whereType<RecentDocument>()
          .toList();
    } catch (_) {
      return <RecentDocument>[];
    }
  }
}
