import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ExportService {
  static Future<Uint8List> buildPdf({
    required String title,
    required String content,
    required int estimatedMinutes,
  }) async {
    final doc = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );

    final paragraphs = _splitToParagraphs(content);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          textDirection: _containsArabic(content)
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
        ),
        theme: theme,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title.isEmpty ? 'Khutbah' : title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.start,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Icon(pw.IconData(0xe8b5), size: 12),
              pw.SizedBox(width: 4),
              pw.Text('Estimated time: $estimatedMinutes min',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 16),
          ...paragraphs.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  p,
                  style: const pw.TextStyle(fontSize: 12, height: 1.4),
                  textAlign: pw.TextAlign.start,
                ),
              )),
        ],
      ),
    );

    return doc.save();
  }

  static String buildHtml({
    required String title,
    required String content,
    required int estimatedMinutes,
  }) {
    final escapedTitle = _htmlEscape(title.isEmpty ? 'Khutbah' : title);
    final htmlBody = _plainTextToHtml(content);

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$escapedTitle</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', Arial, 'Noto Sans Arabic', 'Noto Naskh Arabic', sans-serif; line-height: 1.6; padding: 24px; }
    h1 { margin-top: 0; }
    .meta { color: #666; font-size: 0.9rem; margin-bottom: 16px; }
    p { margin: 0 0 12px; }
    blockquote { margin: 12px 0; padding-left: 12px; border-left: 3px solid #ddd; }
    ul, ol { padding-left: 20px; }
    hr { border: none; border-top: 1px solid #eee; margin: 16px 0; }
  </style>
</head>
<body dir="${_containsArabic(content) ? 'rtl' : 'ltr'}">
  <h1>$escapedTitle</h1>
  <div class="meta">Estimated time: $estimatedMinutes min · Exported from PulpitFlow</div>
  $htmlBody
</body>
</html>''';
  }

  // --- helpers ---
  static List<String> _splitToParagraphs(String text) {
    final lines = text.split('\n');
    final List<String> paras = [];
    final StringBuffer buf = StringBuffer();
    for (final line in lines) {
      if (line.trim().isEmpty) {
        if (buf.isNotEmpty) {
          paras.add(buf.toString().trim());
          buf.clear();
        }
      } else {
        buf.writeln(line.trim());
      }
    }
    if (buf.isNotEmpty) paras.add(buf.toString().trim());
    return paras;
  }

  static bool _containsArabic(String s) {
    // Basic check for Arabic character ranges
    return RegExp(r'[\u0600-\u06FF]').hasMatch(s);
  }

  static String _plainTextToHtml(String text) {
    final paras = _splitToParagraphs(text);
    final buffer = StringBuffer();
    for (final p in paras) {
      buffer.writeln('<p>${_htmlEscape(p).replaceAll('  ', '&nbsp;&nbsp;')}</p>');
    }
    return buffer.toString();
  }

  static String _htmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
