import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_io.dart';

Future<void> saveOrDownloadPdf(Uint8List bytes, String fileName) =>
    downloadPdfFile(bytes, fileName);
