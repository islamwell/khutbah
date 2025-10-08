import 'dart:io';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class HTMLGenerator {
  // Arabic text detection regex - matches Arabic Unicode range
  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  
  /// Detect if text contains Arabic characters
  static bool containsArabic(String text) {
    return _arabicRegex.hasMatch(text);
  }
  
  /// Convert Quill document to HTML with proper formatting and Arabic support
  static String convertToHTML(String title, Document document) {
    // Get the plain text content for language detection
    final plainText = document.toPlainText();
    final hasArabicTitle = containsArabic(title);
    final hasArabicContent = containsArabic(plainText);
    
    // Determine primary language and direction
    final primaryLang = hasArabicContent ? 'ar' : 'en';
    final primaryDir = hasArabicContent ? 'rtl' : 'ltr';
    
    // Convert Quill document to HTML with formatting
    String contentHtml;
    try {
      contentHtml = _convertQuillDeltaToHTML(document);
    } catch (e) {
      // Fallback to plain text with proper formatting
      contentHtml = _convertPlainTextToHTML(plainText);
    }
    
    // Build complete HTML document
    final html = '''<!DOCTYPE html>
<html lang="$primaryLang" dir="$primaryDir">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="PulpitFlow - Islamic Khutbah App">
    <title>${_escapeHtml(title)}</title>
    <style>
        body {
            font-family: ${hasArabicContent ? "'Noto Naskh Arabic', 'Amiri', 'Scheherazade New'" : "'Roboto', 'Arial'"}, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            direction: $primaryDir;
            text-align: ${hasArabicContent ? 'right' : 'left'};
            background-color: #ffffff;
            color: #333333;
        }
        
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 30px;
            direction: ${hasArabicTitle ? 'rtl' : 'ltr'};
            text-align: ${hasArabicTitle ? 'right' : 'left'};
        }
        
        .content {
            font-size: 16px;
            line-height: 1.8;
            text-align: justify;
        }
        
        /* Arabic text styling */
        .arabic {
            font-family: 'Noto Naskh Arabic', 'Amiri', 'Scheherazade New', serif;
            direction: rtl;
            text-align: right;
            font-size: 18px;
        }
        
        /* English text styling */
        .english {
            font-family: 'Roboto', 'Arial', sans-serif;
            direction: ltr;
            text-align: left;
        }
        
        /* Quill editor styles */
        .ql-editor {
            padding: 0;
        }
        
        .ql-editor p {
            margin-bottom: 1em;
        }
        
        .ql-editor strong {
            font-weight: bold;
        }
        
        .ql-editor em {
            font-style: italic;
        }
        
        .ql-editor u {
            text-decoration: underline;
        }
        
        .ql-editor s {
            text-decoration: line-through;
        }
        
        /* Highlight/background color support */
        span[style*="background-color"] {
            padding: 2px 0;
        }
        
        .ql-editor ol, .ql-editor ul {
            margin: 1em 0;
            padding-${hasArabicContent ? 'right' : 'left'}: 2em;
        }
        
        .ql-editor blockquote {
            border-${hasArabicContent ? 'right' : 'left'}: 4px solid #3498db;
            margin: 1em 0;
            padding-${hasArabicContent ? 'right' : 'left'}: 1em;
            background-color: #f8f9fa;
            font-style: italic;
        }
        
        /* Print styles */
        @media print {
            body {
                margin: 0;
                padding: 15mm;
                font-size: 12pt;
            }
            
            h1 {
                font-size: 18pt;
                margin-bottom: 20pt;
            }
            
            .content {
                font-size: 11pt;
                line-height: 1.4;
            }
        }
        
        /* Mobile responsive */
        @media (max-width: 600px) {
            body {
                padding: 15px;
            }
            
            h1 {
                font-size: 24px;
            }
            
            .content {
                font-size: 14px;
            }
        }
    </style>
</head>
<body>
    <h1>${_escapeHtml(title)}</h1>
    <div class="content ${hasArabicContent ? 'arabic' : 'english'}">
        $contentHtml
    </div>
    
    <script>
        // Add language detection and styling for mixed content
        document.addEventListener('DOMContentLoaded', function() {
            const arabicRegex = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/;
            const textNodes = document.createTreeWalker(
                document.body,
                NodeFilter.SHOW_TEXT,
                null,
                false
            );
            
            let node;
            while (node = textNodes.nextNode()) {
                const text = node.textContent;
                if (text && text.trim()) {
                    const parent = node.parentElement;
                    if (arabicRegex.test(text)) {
                        parent.classList.add('arabic');
                        parent.style.direction = 'rtl';
                        parent.style.textAlign = 'right';
                    } else {
                        parent.classList.add('english');
                        parent.style.direction = 'ltr';
                        parent.style.textAlign = 'left';
                    }
                }
            }
        });
    </script>
</body>
</html>''';
    
    return html;
  }
  

  /// Convert Quill Delta to HTML with formatting preservation
  static String _convertQuillDeltaToHTML(Document document) {
    final delta = document.toDelta();
    final buffer = StringBuffer();
    String currentParagraph = '';
    
    for (final operation in delta.operations) {
      if (operation.isInsert) {
        final data = operation.data;
        final attributes = operation.attributes;
        
        if (data is String) {
          String text = data;
          
          // Handle line breaks and paragraphs
          if (text.contains('\n')) {
            final parts = text.split('\n');
            for (int i = 0; i < parts.length; i++) {
              if (parts[i].isNotEmpty) {
                currentParagraph += _applyFormatting(parts[i], attributes);
              }
              
              if (i < parts.length - 1) {
                // End current paragraph and start new one
                if (currentParagraph.trim().isNotEmpty) {
                  buffer.write('<p>$currentParagraph</p>\n');
                  currentParagraph = '';
                }
              }
            }
          } else {
            currentParagraph += _applyFormatting(text, attributes);
          }
        }
      }
    }
    
    // Add any remaining content
    if (currentParagraph.trim().isNotEmpty) {
      buffer.write('<p>$currentParagraph</p>\n');
    }
    
    String result = buffer.toString();
    return result.isNotEmpty ? result : '<p></p>';
  }
  
  /// Apply formatting attributes to text
  static String _applyFormatting(String text, Map<String, dynamic>? attributes) {
    if (text.isEmpty) return text;
    
    String formattedText = _escapeHtml(text);
    
    if (attributes != null) {
      // Debug: Print attributes to see what Quill is sending
      // print('Attributes for "$text": $attributes');
      // Apply bold
      if (attributes['bold'] == true) {
        formattedText = '<strong>$formattedText</strong>';
      }
      
      // Apply italic
      if (attributes['italic'] == true) {
        formattedText = '<em>$formattedText</em>';
      }
      
      // Apply underline
      if (attributes['underline'] == true) {
        formattedText = '<u>$formattedText</u>';
      }
      
      // Apply strikethrough
      if (attributes['strike'] == true) {
        formattedText = '<s>$formattedText</s>';
      }
      
      // Apply color
      if (attributes['color'] != null) {
        final color = attributes['color'];
        formattedText = '<span style="color: $color;">$formattedText</span>';
      }
      
      // Apply background color (highlight)
      // Quill can use 'background' or 'backgroundColor' or 'bg'
      final bgColor = attributes['background'] ?? attributes['backgroundColor'] ?? attributes['bg'];
      if (bgColor != null) {
        formattedText = '<span style="background-color: $bgColor;">$formattedText</span>';
      }
      
      // Apply font size
      if (attributes['size'] != null) {
        final size = attributes['size'];
        formattedText = '<span style="font-size: $size;">$formattedText</span>';
      }
      
      // Apply font family
      if (attributes['font'] != null) {
        final font = attributes['font'];
        formattedText = '<span style="font-family: $font;">$formattedText</span>';
      }
    }
    
    return formattedText;
  }

  /// Convert plain text to HTML with proper paragraph formatting
  static String _convertPlainTextToHTML(String plainText) {
    if (plainText.trim().isEmpty) {
      return '<p></p>';
    }
    
    // Split into paragraphs and convert to HTML
    final paragraphs = plainText.split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '<p>${_escapeHtml(p.trim().replaceAll('\n', '<br>'))}</p>')
        .join('\n');
    
    return paragraphs.isNotEmpty ? paragraphs : '<p>${_escapeHtml(plainText)}</p>';
  }
  
  /// Escape HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
  
  /// Save HTML to device storage
  static Future<String?> saveHTML(String title, Document document) async {
    try {
      // Generating HTML for save
      final html = convertToHTML(title, document);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${directory.path}/$fileName');
      
      // Write HTML with UTF-8 encoding to support Arabic text
      await file.writeAsString(html, encoding: utf8);
      // HTML saved successfully
      return file.path;
    } catch (e) {
      // Error saving HTML
      return null;
    }
  }
  
  /// Share HTML using system share sheet
  static Future<bool> shareHTML(String title, Document document) async {
    try {
      // Generating HTML for share
      final html = convertToHTML(title, document);
      
      // Create temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}.html';
      final file = File('${directory.path}/$fileName');
      
      // Write HTML with UTF-8 encoding
      await file.writeAsString(html, encoding: utf8);
      // HTML created for sharing
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing: $title',
        subject: title,
      );
      
      return true;
    } catch (e) {
      // Error sharing HTML
      return false;
    }
  }
  
  /// Test HTML generation and Arabic text detection
  static Map<String, dynamic> testHTMLGeneration() {
    final testTexts = [
      'Hello World',
      'خطبة الجمعة',
      'بسم الله الرحمن الرحيم',
      'Mixed: Hello مرحبا World',
    ];
    
    final results = <String, dynamic>{
      'textDetection': {},
      'htmlSamples': {},
    };
    
    for (final text in testTexts) {
      results['textDetection'][text] = containsArabic(text);
      
      // Create a simple document for testing
      final doc = Document()..insert(0, text);
      final html = convertToHTML('Test Title', doc);
      results['htmlSamples'][text] = html.length; // Store length to avoid huge output
    }
    
    return results;
  }
}