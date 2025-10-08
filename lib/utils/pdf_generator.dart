import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_quill/flutter_quill.dart';

class PDFGenerator {
  static pw.Font? _arabicFont;
  static pw.Font? _defaultFont;
  static bool _fontsInitialized = false;
  
  // Arabic text detection regex - matches Arabic Unicode range
  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  
  /// Initialize fonts for PDF generation
  static Future<void> _initializeFonts() async {
    if (_fontsInitialized) return;
    
    try {
      // Try multiple Arabic font sources
      final arabicFontUrls = [
        'https://fonts.gstatic.com/s/notonaskharabic/v20/RrQIbot3K-83bxAATe4OuBLyzXoYOjvKlT7lEeOxWA.ttf',
        'https://fonts.gstatic.com/s/amiri/v27/J7aRnpd8CGxBHqUpvrIw74NL.ttf',
        'https://fonts.gstatic.com/s/scheherazadenew/v15/4UaZrEtFpBI4f1ZSIK9d4LqX8SiJsvxrWn7D.ttf',
      ];
      
      bool fontLoaded = false;
      
      for (final fontUrl in arabicFontUrls) {
        try {
          print('Attempting to load Arabic font from: $fontUrl');
          final response = await http.get(
            Uri.parse(fontUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final fontData = response.bodyBytes.buffer.asByteData();
            _arabicFont = pw.Font.ttf(fontData);
            print('Arabic font loaded successfully from: $fontUrl');
            fontLoaded = true;
            break;
          }
        } catch (e) {
          print('Failed to load font from $fontUrl: $e');
          continue;
        }
      }
      
      if (!fontLoaded) {
        // Try using system fonts through printing package
        try {
          final systemFonts = await PdfGoogleFonts.notoNaskhArabicRegular();
          _arabicFont = systemFonts;
          print('Loaded Arabic font from system/Google Fonts');
          fontLoaded = true;
        } catch (e) {
          print('Failed to load system Arabic font: $e');
        }
      }
      
      // Load default font
      try {
        _defaultFont = await PdfGoogleFonts.robotoRegular();
        print('Loaded default font from Google Fonts');
      } catch (e) {
        _defaultFont = pw.Font.helvetica();
        print('Using Helvetica as default font');
      }
      
      // If no Arabic font loaded, use default as fallback
      if (!fontLoaded) {
        _arabicFont = _defaultFont;
        print('Warning: Using default font for Arabic text - characters may not render correctly');
      }
      
      _fontsInitialized = true;
      print('Font initialization completed');
      
    } catch (e) {
      // Ultimate fallback
      _arabicFont = pw.Font.helvetica();
      _defaultFont = pw.Font.helvetica();
      _fontsInitialized = true;
      print('Font initialization failed, using Helvetica: $e');
    }
  }
  
  /// Reset font cache (useful for testing or if fonts fail to load)
  static void resetFonts() {
    _arabicFont = null;
    _defaultFont = null;
    _fontsInitialized = false;
  }
  
  /// Test font loading and Arabic text detection
  static Future<Map<String, dynamic>> testFontSupport() async {
    await _initializeFonts();
    
    final testTexts = [
      'Hello World',
      'خطبة الجمعة',
      'بسم الله الرحمن الرحيم',
      'Mixed: Hello مرحبا World',
    ];
    
    final textDetection = <String, bool>{};
    for (final text in testTexts) {
      textDetection[text] = containsArabic(text);
    }
    
    final results = <String, dynamic>{
      'arabicFontLoaded': _arabicFont != null && _arabicFont != pw.Font.helvetica(),
      'defaultFontLoaded': _defaultFont != null,
      'fontsInitialized': _fontsInitialized,
      'textDetection': textDetection,
    };
    
    return results;
  }
  
  /// Detect if text contains Arabic characters
  static bool containsArabic(String text) {
    return _arabicRegex.hasMatch(text);
  }
  
  /// Generate PDF document from title and rich content
  static Future<pw.Document> generatePDFFromDocument(String title, Document document) async {
    await _initializeFonts();
    
    final pdf = pw.Document();
    
    // Get plain text for language detection
    final plainContent = document.toPlainText();
    
    // Determine if content contains Arabic text
    final hasArabicTitle = containsArabic(title);
    final hasArabicContent = containsArabic(plainContent);
    
    // Create font fallback list for better Unicode support
    final List<pw.Font> fontFallbacks = [
      if (_arabicFont != null) _arabicFont!,
      if (_defaultFont != null) _defaultFont!,
    ];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title
            pw.Container(
              alignment: hasArabicTitle ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: hasArabicTitle ? _arabicFont : _defaultFont,
                  fontFallback: fontFallbacks,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: hasArabicTitle ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Content with formatting
            pw.Container(
              alignment: hasArabicContent ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              child: _buildRichContent(document, hasArabicContent, fontFallbacks),
            ),
          ];
        },
      ),
    );
    
    return pdf;
  }

  /// Generate PDF document from title and plain content (backward compatibility)
  static Future<pw.Document> generatePDF(String title, String content) async {
    // Create a simple document from plain text
    final document = Document()..insert(0, content);
    return generatePDFFromDocument(title, document);
  }

  /// Build rich content for PDF with formatting
  static pw.Widget _buildRichContent(Document document, bool isArabic, List<pw.Font> fontFallbacks) {
    final delta = document.toDelta();
    final widgets = <pw.Widget>[];
    final currentParagraph = <pw.InlineSpan>[];
    
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
                currentParagraph.add(_createTextSpan(parts[i], attributes, isArabic, fontFallbacks));
              }
              
              if (i < parts.length - 1) {
                // End current paragraph and start new one
                if (currentParagraph.isNotEmpty) {
                  widgets.add(pw.RichText(
                    text: pw.TextSpan(children: List.from(currentParagraph)),
                    textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  ));
                  widgets.add(pw.SizedBox(height: 8)); // Add spacing between paragraphs
                  currentParagraph.clear();
                }
              }
            }
          } else {
            currentParagraph.add(_createTextSpan(text, attributes, isArabic, fontFallbacks));
          }
        }
      }
    }
    
    // Add any remaining content
    if (currentParagraph.isNotEmpty) {
      widgets.add(pw.RichText(
        text: pw.TextSpan(children: currentParagraph),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
      ));
    }
    
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: widgets.isNotEmpty ? widgets : [
        pw.Text(
          document.toPlainText(),
          style: pw.TextStyle(
            font: isArabic ? _arabicFont : _defaultFont,
            fontFallback: fontFallbacks,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Create text span with formatting
  static pw.TextSpan _createTextSpan(String text, Map<String, dynamic>? attributes, bool isArabic, List<pw.Font> fontFallbacks) {
    pw.FontWeight? fontWeight;
    pw.FontStyle? fontStyle;
    PdfColor? color;
    double fontSize = 12;
    
    if (attributes != null) {
      // Apply bold
      if (attributes['bold'] == true) {
        fontWeight = pw.FontWeight.bold;
      }
      
      // Apply italic
      if (attributes['italic'] == true) {
        fontStyle = pw.FontStyle.italic;
      }
      
      // Apply color (convert hex string to PdfColor)
      if (attributes['color'] != null) {
        try {
          final colorStr = attributes['color'].toString();
          if (colorStr.startsWith('#')) {
            final hex = colorStr.substring(1);
            final r = int.parse(hex.substring(0, 2), radix: 16);
            final g = int.parse(hex.substring(2, 4), radix: 16);
            final b = int.parse(hex.substring(4, 6), radix: 16);
            color = PdfColor.fromInt(0xFF000000 | (r << 16) | (g << 8) | b);
          }
        } catch (e) {
          // Ignore color parsing errors
        }
      }
      
      // Apply font size
      if (attributes['size'] != null) {
        try {
          final sizeStr = attributes['size'].toString();
          if (sizeStr.endsWith('px')) {
            fontSize = double.parse(sizeStr.replaceAll('px', ''));
          } else {
            fontSize = double.parse(sizeStr);
          }
        } catch (e) {
          fontSize = 12; // Default
        }
      }
    }
    
    return pw.TextSpan(
      text: text,
      style: pw.TextStyle(
        font: isArabic ? _arabicFont : _defaultFont,
        fontFallback: fontFallbacks,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        fontSize: fontSize,
      ),
    );
  }
  
  /// Get Downloads directory (Android/iOS compatible)
  static Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try to get external storage directory for Android
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }
        // Fallback to external storage directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadsDir = Directory('${externalDir.path}/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory as Downloads equivalent
        return await getApplicationDocumentsDirectory();
      }
      
      // Fallback to Documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      print('Error getting Downloads directory: $e');
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Request storage permissions
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Check Android version and request appropriate permissions
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 33) {
          // Android 13+ (API 33+) - Use scoped storage, no special permissions needed for Downloads
          return true;
        } else if (sdkInt >= 30) {
          // Android 11-12 (API 30-32) - Check manage external storage
          if (await Permission.manageExternalStorage.isGranted) {
            return true;
          }
          final status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        } else {
          // Android 10 and below - Use legacy storage permission
          if (await Permission.storage.isGranted) {
            return true;
          }
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }
      
      // iOS doesn't need explicit storage permissions for app documents
      return true;
    } catch (e) {
      print('Error requesting storage permission: $e');
      // Fallback - try to save anyway
      return true;
    }
  }

  /// Save PDF to Downloads folder
  static Future<String?> savePDF(String title, String content) async {
    try {
      print('Generating PDF for save...');
      
      // Request storage permission
      if (!await _requestStoragePermission()) {
        print('Storage permission denied');
        return null;
      }
      
      final pdf = await generatePDF(title, content);
      final bytes = await pdf.save();
      
      // Get the downloads directory
      final directory = await _getDownloadsDirectory();
      if (directory == null) {
        print('Could not access Downloads directory');
        return null;
      }
      
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      print('PDF saved successfully to Downloads: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  /// Save PDF to Downloads folder with rich formatting
  static Future<String?> savePDFFromDocument(String title, Document document) async {
    try {
      print('Generating PDF for save...');
      
      // Request storage permission
      if (!await _requestStoragePermission()) {
        print('Storage permission denied');
        return null;
      }
      
      final pdf = await generatePDFFromDocument(title, document);
      final bytes = await pdf.save();
      
      // Get the downloads directory
      final directory = await _getDownloadsDirectory();
      if (directory == null) {
        print('Could not access Downloads directory');
        return null;
      }
      
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      print('PDF saved successfully to Downloads: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  /// Save PDF with user-selected location and rich formatting
  static Future<String?> savePDFWithPickerFromDocument(String title, Document document) async {
    try {
      print('Generating PDF for save with picker...');
      final pdf = await generatePDFFromDocument(title, document);
      final bytes = await pdf.save();
      
      // Clean title for filename
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '');
      final defaultFileName = '${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        print('PDF saved successfully to user location: ${file.path}');
        return file.path;
      } else {
        print('User cancelled save operation');
        return null;
      }
    } catch (e) {
      print('Error saving PDF with picker: $e');
      return null;
    }
  }

  /// Save PDF with user-selected location (backward compatibility)
  static Future<String?> savePDFWithPicker(String title, String content) async {
    try {
      print('Generating PDF for save with picker...');
      final pdf = await generatePDF(title, content);
      final bytes = await pdf.save();
      
      // Clean title for filename
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '');
      final defaultFileName = '${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        print('PDF saved successfully to user location: ${file.path}');
        return file.path;
      } else {
        print('User cancelled save operation');
        return null;
      }
    } catch (e) {
      print('Error saving PDF with picker: $e');
      return null;
    }
  }
  
  /// Print PDF using system print dialog with rich formatting
  static Future<bool> printPDFFromDocument(String title, Document document) async {
    try {
      print('Generating PDF for print...');
      final pdf = await generatePDFFromDocument(title, document);
      final bytes = await pdf.save();
      
      print('Opening print dialog...');
      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: title,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      return false;
    }
  }

  /// Print PDF using system print dialog (backward compatibility)
  static Future<bool> printPDF(String title, String content) async {
    try {
      print('Generating PDF for print...');
      final pdf = await generatePDF(title, content);
      final bytes = await pdf.save();
      
      print('Opening print dialog...');
      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: title,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      return false;
    }
  }
  
  /// Share PDF using system share sheet with rich formatting
  static Future<bool> sharePDFFromDocument(String title, Document document) async {
    try {
      print('Generating PDF for share...');
      final pdf = await generatePDFFromDocument(title, document);
      final bytes = await pdf.save();
      
      // Create temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      print('PDF created for sharing: ${file.path}');
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing: $title',
        subject: title,
      );
      
      return true;
    } catch (e) {
      print('Error sharing PDF: $e');
      return false;
    }
  }

  /// Share PDF using system share sheet (backward compatibility)
  static Future<bool> sharePDF(String title, String content) async {
    try {
      print('Generating PDF for share...');
      final pdf = await generatePDF(title, content);
      final bytes = await pdf.save();
      
      // Create temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      print('PDF created for sharing: ${file.path}');
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing: $title',
        subject: title,
      );
      
      return true;
    } catch (e) {
      print('Error sharing PDF: $e');
      return false;
    }
  }
}