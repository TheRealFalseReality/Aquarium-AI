// Stub implementation for non-web platforms
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String fileName) {
  throw UnsupportedError('Web download not supported on this platform');
}