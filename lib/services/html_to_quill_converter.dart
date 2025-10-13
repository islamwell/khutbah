import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlToQuillConverter {
  static Document convertHtmlToQuill(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      final body = document.body;
      
      if (body == null) {
        final doc = Document();
        doc.insert(0, 'No content found\n');
        return doc;
      }

      final quillDocument = Document();
      int currentIndex = 0;

      for (final node in body.nodes) {
        currentIndex = _processNode(node, quillDocument, currentIndex);
      }

      // Ensure document has at least one character
      if (quillDocument.length == 0) {
        quillDocument.insert(0, '\n');
      }

      return quillDocument;
    } catch (e) {
      // If conversion fails, return a document with error message
      final doc = Document();
      doc.insert(0, 'Error converting HTML: $e\n');
      return doc;
    }
  }

  static int _processNode(dom.Node node, Document document, int index) {
    try {
      if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          document.insert(index, text);
          return index + text.length;
        }
        return index;
      }

      if (node is dom.Element) {
        return _processElement(node, document, index);
      }

      return index;
    } catch (e) {
      print('Error processing node: $e');
      return index;
    }
  }

  static int _processElement(dom.Element element, Document document, int index) {
    final tagName = element.localName?.toLowerCase();
    final className = element.className;
    
    switch (tagName) {
      case 'h1':
        return _insertHeading(element, document, index, 1);
      case 'h2':
        return _insertHeading(element, document, index, 2);
      case 'h3':
        return _insertHeading(element, document, index, 3);
      case 'p':
        return _insertParagraph(element, document, index, className);
      case 'div':
        return _insertDiv(element, document, index, className);
      case 'strong':
      case 'b':
        return _insertBold(element, document, index);
      case 'em':
      case 'i':
        return _insertItalic(element, document, index);
      case 'ul':
        return _insertList(element, document, index, false);
      case 'ol':
        return _insertList(element, document, index, true);
      case 'li':
        return _insertListItem(element, document, index);
      case 'br':
        document.insert(index, '\n');
        return index + 1;
      case 'table':
        return _insertTable(element, document, index);
      default:
        // Process children for unknown elements
        return _processChildren(element, document, index);
    }
  }

  static int _insertHeading(dom.Element element, Document document, int index, int level) {
    try {
      final text = element.text.trim();
      if (text.isEmpty) return index;

      // Add spacing before heading (except first element)
      if (index > 0) {
        document.insert(index, '\n');
        index++;
      }

      final startIndex = index;
      document.insert(index, text);
      index += text.length;
      
      // Apply heading style - must be done after text is inserted
      document.format(startIndex, text.length, Attribute.fromKeyValue('header', level));
      
      document.insert(index, '\n');
      return index + 1;
    } catch (e) {
      print('Error inserting heading: $e');
      return index;
    }
  }

  static int _insertParagraph(dom.Element element, Document document, int index, String className) {
    try {
      final text = element.text.trim();
      if (text.isEmpty) return _processChildren(element, document, index);

      // Add spacing before paragraph
      if (index > 0) {
        document.insert(index, '\n');
        index++;
      }

      final startIndex = index;
      document.insert(index, text);
      index += text.length;
      
      // Apply class-specific formatting after text is inserted
      if (className.contains('arabic')) {
        document.format(startIndex, text.length, Attribute.bold);
      } else if (className.contains('translation')) {
        document.format(startIndex, text.length, Attribute.italic);
      } else if (className.contains('subtitle')) {
        document.format(startIndex, text.length, Attribute.italic);
      } else if (className.contains('reference')) {
        document.format(startIndex, text.length, Attribute.italic);
      }

      document.insert(index, '\n');
      return index + 1;
    } catch (e) {
      print('Error inserting paragraph: $e');
      return index;
    }
  }

  static int _insertDiv(dom.Element element, Document document, int index, String className) {
    // Add spacing before div
    if (index > 0 && className.isNotEmpty) {
      document.insert(index, '\n');
      index++;
    }

    // Add class indicator for special divs
    if (className.contains('opening')) {
      document.insert(index, '📖 ');
      document.format(index, 2, Attribute.bold);
      index += 2;
    } else if (className.contains('key-point')) {
      document.insert(index, '💡 KEY POINT: ');
      document.format(index, 14, Attribute.bold);
      document.format(index, 14, Attribute.fromKeyValue('color', '#f9a825'));
      index += 14;
    } else if (className.contains('hadith-box')) {
      document.insert(index, '📚 HADITH: ');
      document.format(index, 11, Attribute.bold);
      document.format(index, 11, Attribute.fromKeyValue('color', '#1976d2'));
      index += 11;
    } else if (className.contains('scholar-quote')) {
      document.insert(index, '👨‍🏫 SCHOLAR: ');
      document.format(index, 13, Attribute.bold);
      document.format(index, 13, Attribute.fromKeyValue('color', '#7b1fa2'));
      index += 13;
    } else if (className.contains('remember')) {
      document.insert(index, '⚠️ REMEMBER: ');
      document.format(index, 13, Attribute.bold);
      document.format(index, 13, Attribute.fromKeyValue('color', '#c62828'));
      index += 13;
    } else if (className.contains('action-box')) {
      document.insert(index, '✅ ACTION: ');
      document.format(index, 11, Attribute.bold);
      document.format(index, 11, Attribute.fromKeyValue('color', '#2c5f2d'));
      index += 11;
    } else if (className.contains('pause')) {
      document.insert(index, '\n* * *\n');
      document.format(index + 1, 5, Attribute.fromKeyValue('align', 'center'));
      document.format(index + 1, 5, Attribute.fromKeyValue('color', '#cccccc'));
      return index + 7;
    }

    return _processChildren(element, document, index);
  }

  static int _insertBold(dom.Element element, Document document, int index) {
    try {
      final text = element.text.trim();
      if (text.isEmpty) return index;

      final startIndex = index;
      document.insert(index, text);
      index += text.length;
      
      document.format(startIndex, text.length, Attribute.bold);
      
      return index;
    } catch (e) {
      print('Error inserting bold: $e');
      return index;
    }
  }

  static int _insertItalic(dom.Element element, Document document, int index) {
    try {
      final text = element.text.trim();
      if (text.isEmpty) return index;

      final startIndex = index;
      document.insert(index, text);
      index += text.length;
      
      document.format(startIndex, text.length, Attribute.italic);
      
      return index;
    } catch (e) {
      print('Error inserting italic: $e');
      return index;
    }
  }

  static int _insertList(dom.Element element, Document document, int index, bool ordered) {
    try {
      // Add spacing before list
      if (index > 0) {
        document.insert(index, '\n');
        index++;
      }

      for (final child in element.children) {
        if (child.localName == 'li') {
          final text = child.text.trim();
          if (text.isNotEmpty) {
            final startIndex = index;
            document.insert(index, text);
            index += text.length;
            
            // Apply list formatting after text is inserted
            if (ordered) {
              document.format(startIndex, text.length, Attribute.ol);
            } else {
              document.format(startIndex, text.length, Attribute.ul);
            }
            
            document.insert(index, '\n');
            index++;
          }
        }
      }

      return index;
    } catch (e) {
      print('Error inserting list: $e');
      return index;
    }
  }

  static int _insertListItem(dom.Element element, Document document, int index) {
    final text = element.text.trim();
    if (text.isEmpty) return index;

    document.insert(index, '• $text');
    index += text.length + 2;
    document.insert(index, '\n');
    return index + 1;
  }

  static int _insertTable(dom.Element element, Document document, int index) {
    // Add spacing before table
    if (index > 0) {
      document.insert(index, '\n');
      index++;
    }

    document.insert(index, '📊 TABLE:\n');
    document.format(index, 8, Attribute.bold);
    index += 9;

    for (final row in element.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td, th');
      final rowText = cells.map((cell) => cell.text.trim()).join(' | ');
      
      if (rowText.isNotEmpty) {
        document.insert(index, rowText);
        
        // Bold headers
        if (row.querySelector('th') != null) {
          document.format(index, rowText.length, Attribute.bold);
        }
        
        index += rowText.length;
        document.insert(index, '\n');
        index++;
      }
    }

    return index;
  }

  static int _processChildren(dom.Element element, Document document, int index) {
    for (final child in element.nodes) {
      index = _processNode(child, document, index);
    }
    return index;
  }
}