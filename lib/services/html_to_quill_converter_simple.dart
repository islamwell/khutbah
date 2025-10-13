import 'package:flutter_quill/flutter_quill.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlToQuillConverterSimple {
  static Document convertHtmlToQuill(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      final body = document.body;
      
      if (body == null) {
        return _createEmptyDocument('No content found');
      }

      // Extract plain text with basic formatting
      final buffer = StringBuffer();
      _extractText(body, buffer);
      
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        return _createEmptyDocument('Empty template');
      }

      // Create Quill document with the text
      final quillDoc = Document();
      quillDoc.insert(0, text);
      quillDoc.insert(text.length, '\n');
      
      return quillDoc;
    } catch (e) {
      print('Error converting HTML: $e');
      return _createEmptyDocument('Error: $e');
    }
  }

  static Document _createEmptyDocument(String message) {
    final doc = Document();
    doc.insert(0, '$message\n');
    return doc;
  }

  static void _extractText(dom.Node node, StringBuffer buffer) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isNotEmpty) {
        buffer.write(text);
        buffer.write(' ');
      }
    } else if (node is dom.Element) {
      final tagName = node.localName?.toLowerCase();
      
      // Add line breaks for block elements
      if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3') {
        buffer.write('\n\n');
        buffer.write('# ');
      } else if (tagName == 'p' || tagName == 'div') {
        buffer.write('\n');
      } else if (tagName == 'br') {
        buffer.write('\n');
      } else if (tagName == 'li') {
        buffer.write('\n• ');
      }
      
      // Process children
      for (final child in node.nodes) {
        _extractText(child, buffer);
      }
      
      // Add line breaks after block elements
      if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3' || 
          tagName == 'p' || tagName == 'div') {
        buffer.write('\n');
      }
    }
  }
}
