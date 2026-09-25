// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadPdfFile(Uint8List bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..target = '_blank'
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    // Keep object URL alive for 60 seconds so browser completes download transfer
    Future.delayed(const Duration(seconds: 60), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });
  } catch (e) {
    // Robust fallback: Data URI download
    final base64String = base64Encode(bytes);
    final dataUri = 'data:application/pdf;base64,$base64String';
    final anchor = html.AnchorElement(href: dataUri)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }
}
