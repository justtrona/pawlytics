import 'dart:typed_data';

/// Stub for non-web (mobile/desktop)
Future<void> triggerWebDownload(Uint8List bytes, String fileName) async {
  // Does nothing on mobile
}
