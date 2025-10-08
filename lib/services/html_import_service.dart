import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:pulpitflow/models/khutbah.dart';

class HtmlImportService {
  static Khutbah parseHtmlToKhutbah(String htmlString) {
    final doc = html_parser.parse(htmlString);

    // Title: prefer <title>, then first <h1>, else fallback
    final titleTag = doc.querySelector('title')?.text.trim();
    final h1Tag = doc.querySelector('h1')?.text.trim();
    final title = (titleTag?.isNotEmpty == true
            ? titleTag
            : (h1Tag?.isNotEmpty == true ? h1Tag : 'Imported Khutbah')) ??
        'Imported Khutbah';

    // Extract body text with basic paragraph line breaks
    final body = doc.body;
    final content = _extractTextWithLineBreaks(body);

    final now = DateTime.now();
    return Khutbah(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content.trim(),
      tags: const <String>['imported'],
      createdAt: now,
      modifiedAt: now,
      estimatedMinutes: _estimateMinutes(content),
    );
  }

  static String _extractTextWithLineBreaks(dom.Element? body) {
    if (body == null) return '';

    final buffer = StringBuffer();

    void walk(dom.Node node) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        if (tag == 'br') {
          buffer.writeln();
        }
        if (tag == 'p' || tag == 'div' || tag == 'section' || tag == 'article' || tag == 'li' || tag == 'h1' || tag == 'h2' || tag == 'h3') {
          // Start block
        }
        for (final child in node.nodes) {
          walk(child);
        }
        if (tag == 'p' || tag == 'div' || tag == 'section' || tag == 'article' || tag == 'li') {
          buffer.writeln('\n');
        }
        if (tag == 'h1' || tag == 'h2' || tag == 'h3') {
          buffer.writeln('\n');
        }
      } else if (node is dom.Text) {
        final text = node.text.replaceAll('\u00A0', ' ').trim();
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(text);
        }
      }
    }

    walk(body);
    // Normalize multiple blank lines
    final normalized = buffer
        .toString()
        .replaceAll(RegExp(r'\s+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return normalized;
  }

  static int _estimateMinutes(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 150).ceil().clamp(5, 60);
  }
}
