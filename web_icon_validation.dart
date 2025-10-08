import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// PWA Icon Validation Script
/// Validates web icon assets for PWA compliance according to requirements 3.3
void main() async {
  print('🔍 Starting PWA Icon Validation...\n');
  
  final validator = WebIconValidator();
  await validator.validateAllIcons();
}

class WebIconValidator {
  static const String webDir = 'web';
  static const String iconsDir = 'web/icons';
  static const String manifestPath = 'web/manifest.json';
  
  // Required PWA icon sizes according to web standards
  static const Map<String, List<int>> requiredIconSizes = {
    'any': [192, 512],
    'maskable': [192, 512],
  };
  
  // Additional recommended sizes for better PWA experience
  static const Map<String, List<int>> recommendedIconSizes = {
    'any': [72, 96, 128, 144, 152, 384],
    'maskable': [72, 96, 128, 144, 152, 384],
  };

  Future<void> validateAllIcons() async {
    print('📋 PWA Icon Validation Report');
    print('=' * 50);
    
    // Check if web directory exists
    if (!await Directory(webDir).exists()) {
      print('❌ ERROR: Web directory not found at $webDir');
      return;
    }
    
    // Check if icons directory exists
    if (!await Directory(iconsDir).exists()) {
      print('❌ ERROR: Icons directory not found at $iconsDir');
      return;
    }
    
    // Validate manifest.json
    await _validateManifest();
    
    // Validate icon files
    await _validateIconFiles();
    
    // Check for missing required icons
    await _checkMissingIcons();
    
    // Validate maskable icon compliance
    await _validateMaskableCompliance();
    
    print('\n✅ PWA Icon validation completed!');
  }
  
  Future<void> _validateManifest() async {
    print('\n🔍 Validating manifest.json...');
    
    final manifestFile = File(manifestPath);
    if (!await manifestFile.exists()) {
      print('❌ ERROR: manifest.json not found at $manifestPath');
      return;
    }
    
    try {
      final manifestContent = await manifestFile.readAsString();
      final manifest = json.decode(manifestContent) as Map<String, dynamic>;
      
      if (!manifest.containsKey('icons')) {
        print('❌ ERROR: No icons array found in manifest.json');
        return;
      }
      
      final icons = manifest['icons'] as List<dynamic>;
      print('✅ Found ${icons.length} icon entries in manifest.json');
      
      // Validate each icon entry
      for (int i = 0; i < icons.length; i++) {
        final icon = icons[i] as Map<String, dynamic>;
        _validateIconEntry(icon, i);
      }
      
    } catch (e) {
      print('❌ ERROR: Failed to parse manifest.json: $e');
    }
  }
  
  void _validateIconEntry(Map<String, dynamic> icon, int index) {
    print('  Icon ${index + 1}:');
    
    // Check required fields
    final requiredFields = ['src', 'sizes', 'type'];
    for (final field in requiredFields) {
      if (!icon.containsKey(field)) {
        print('    ❌ Missing required field: $field');
      } else {
        print('    ✅ $field: ${icon[field]}');
      }
    }
    
    // Check purpose field (important for PWA)
    if (icon.containsKey('purpose')) {
      print('    ✅ purpose: ${icon['purpose']}');
    } else {
      print('    ⚠️  Missing purpose field (defaults to "any")');
    }
  }
  
  Future<void> _validateIconFiles() async {
    print('\n🔍 Validating icon files...');
    
    final iconsDirectory = Directory(iconsDir);
    final iconFiles = await iconsDirectory.list().toList();
    
    for (final file in iconFiles) {
      if (file is File && file.path.endsWith('.png')) {
        await _validateIconFile(file);
      }
    }
  }
  
  Future<void> _validateIconFile(File iconFile) async {
    final fileName = iconFile.path.split(Platform.pathSeparator).last;
    print('  Checking $fileName...');
    
    try {
      final bytes = await iconFile.readAsBytes();
      
      // Basic PNG validation (check PNG signature)
      if (bytes.length < 8 || 
          bytes[0] != 0x89 || bytes[1] != 0x50 || bytes[2] != 0x4E || bytes[3] != 0x47) {
        print('    ❌ Invalid PNG format');
        return;
      }
      
      print('    ✅ Valid PNG format');
      print('    ✅ File size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      
      // Extract dimensions from PNG header
      final dimensions = _extractPngDimensions(bytes);
      if (dimensions != null) {
        print('    ✅ Dimensions: ${dimensions['width']}x${dimensions['height']}');
        
        // Check if it's square (required for icons)
        if (dimensions['width'] != dimensions['height']) {
          print('    ⚠️  Icon is not square (recommended for PWA icons)');
        }
      }
      
    } catch (e) {
      print('    ❌ Error reading file: $e');
    }
  }
  
  Map<String, int>? _extractPngDimensions(Uint8List bytes) {
    try {
      // PNG IHDR chunk starts at byte 16
      if (bytes.length < 24) return null;
      
      final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      
      return {'width': width, 'height': height};
    } catch (e) {
      return null;
    }
  }
  
  Future<void> _checkMissingIcons() async {
    print('\n🔍 Checking for required PWA icons...');
    
    final iconsDirectory = Directory(iconsDir);
    final existingFiles = await iconsDirectory.list()
        .where((file) => file is File && file.path.endsWith('.png'))
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList();
    
    // Check required icons
    for (final purpose in requiredIconSizes.keys) {
      for (final size in requiredIconSizes[purpose]!) {
        final expectedFileName = purpose == 'any' 
            ? 'Icon-$size.png' 
            : 'Icon-$purpose-$size.png';
        
        if (existingFiles.contains(expectedFileName)) {
          print('  ✅ Required: $expectedFileName');
        } else {
          print('  ❌ Missing required: $expectedFileName');
        }
      }
    }
    
    // Check recommended icons
    print('\n📋 Recommended additional icons:');
    for (final purpose in recommendedIconSizes.keys) {
      for (final size in recommendedIconSizes[purpose]!) {
        final expectedFileName = purpose == 'any' 
            ? 'Icon-$size.png' 
            : 'Icon-$purpose-$size.png';
        
        if (existingFiles.contains(expectedFileName)) {
          print('  ✅ Recommended: $expectedFileName');
        } else {
          print('  ⚠️  Missing recommended: $expectedFileName');
        }
      }
    }
  }
  
  Future<void> _validateMaskableCompliance() async {
    print('\n🔍 Validating maskable icon compliance...');
    
    // Check if maskable icons exist
    final maskableIcons = ['Icon-maskable-192.png', 'Icon-maskable-512.png'];
    
    for (final iconName in maskableIcons) {
      final iconFile = File('$iconsDir/$iconName');
      if (await iconFile.exists()) {
        print('  ✅ Maskable icon found: $iconName');
        await _checkMaskableIconGuidelines(iconFile);
      } else {
        print('  ❌ Missing maskable icon: $iconName');
      }
    }
  }
  
  Future<void> _checkMaskableIconGuidelines(File iconFile) async {
    print('    📋 Maskable icon guidelines:');
    print('    ✅ Icon should have important content in safe zone (center 80%)');
    print('    ✅ Icon should work when cropped to circle, rounded rectangle, or other shapes');
    print('    ✅ Icon should have sufficient padding around important elements');
    print('    ℹ️  Manual review recommended for optimal maskable icon design');
  }
}