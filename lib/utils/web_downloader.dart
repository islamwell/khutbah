import 'dart:typed_data';

import 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart';

// Expose a single API; on non-web this throws UnsupportedError if called.
Future<void> downloadBytesWeb(String filename, Uint8List bytes, {String mimeType = 'application/octet-stream'}) async {
  await webDownloadBytes(filename, bytes, mimeType: mimeType);
}
