// Web implementation for file downloads
import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create an anchor element to trigger the download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  
  // Add to document, click, and remove
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  // Revoke the URL after a short delay to ensure the browser has
  // enough time to process the download before the URL becomes invalid.
  // 100ms is sufficient for all modern browsers to initiate the download.
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });
}