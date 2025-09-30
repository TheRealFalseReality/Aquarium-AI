// Web implementation for file downloads
import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.Url.revokeObjectUrl(url);
}