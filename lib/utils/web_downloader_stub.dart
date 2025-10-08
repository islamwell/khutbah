import 'dart:typed_data';

Future<void> webDownloadBytes(String filename, Uint8List bytes, {String mimeType = 'application/octet-stream'}) async {
  // Stub for non-web platforms; do nothing.
  throw UnsupportedError('webDownloadBytes is only supported on web');
}
