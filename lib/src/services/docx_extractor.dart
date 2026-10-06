import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Extrae el texto de un archivo DOCX.
///
/// Un `.docx` es un ZIP que contiene `word/document.xml` (WordprocessingML).
/// Se recorren los párrafos (`w:p`) y se concatena su contenido de texto
/// (`w:t`), respetando tabulaciones (`w:tab`) y saltos de línea (`w:br`).
class DocxExtractor {
  const DocxExtractor._();

  /// Devuelve el texto plano del documento, párrafo por párrafo.
  /// Se ejecuta en un isolate para no bloquear la interfaz.
  static Future<String> extractText(String filePath) {
    return Isolate.run(() => _extractSync(filePath));
  }

  static String _extractSync(String filePath) {
    final List<int> bytes = File(filePath).readAsBytesSync();

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('El archivo no es un DOCX válido (ZIP corrupto).');
    }

    final ArchiveFile? documentXml = archive.findFile('word/document.xml');
    if (documentXml == null) {
      throw const FormatException(
        'El archivo no contiene "word/document.xml". ¿Es realmente un DOCX?',
      );
    }

    final XmlDocument document;
    try {
      final List<int> content = (documentXml.content as List<dynamic>).cast<int>();
      document = XmlDocument.parse(utf8.decode(content, allowMalformed: true));
    } catch (_) {
      throw const FormatException('No se pudo interpretar el contenido del documento.');
    }

    final StringBuffer out = StringBuffer();
    // Se comparan nombres locales para tolerar distintos prefijos de namespace.
    for (final XmlElement paragraph in document.descendantElements
        .where((XmlElement e) => e.name.local == 'p')) {
      final StringBuffer line = StringBuffer();
      for (final XmlElement node in paragraph.descendantElements) {
        switch (node.name.local) {
          case 't':
            line.write(node.innerText);
          case 'tab':
            line.write('\t');
          case 'br':
          case 'cr':
            line.write('\n');
        }
      }
      out.writeln(line.toString());
    }

    final String text = out.toString().trimRight();
    if (text.isEmpty) {
      throw const FormatException('El documento no contiene texto legible.');
    }
    return text;
  }
}
