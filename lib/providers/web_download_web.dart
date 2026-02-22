// Web implementation for file downloads
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadFile(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
  );
  final url = web.URL.createObjectURL(blob);

  // Create an anchor element to trigger the download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  // Add to document, click, and remove
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Revoke the URL after a short delay to ensure the browser has
  // enough time to process the download before the URL becomes invalid.
  // 100ms is sufficient for all modern browsers to initiate the download.
  Future.delayed(const Duration(milliseconds: 100), () {
    web.URL.revokeObjectURL(url);
  });
}
