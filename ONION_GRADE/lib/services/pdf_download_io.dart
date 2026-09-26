import 'dart:io';
import 'dart:typed_data';

Future<void> downloadPdfFile(Uint8List bytes, String fileName) async {
  // Determine standard downloads directory or current directory
  String targetPath = fileName;
  try {
    final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userProfile != null) {
      final downloadsDir = Directory('$userProfile${Platform.pathSeparator}Downloads');
      if (downloadsDir.existsSync()) {
        targetPath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';
      }
    }
  } catch (_) {}

  final file = File(targetPath);
  await file.writeAsBytes(bytes, flush: true);

  // If on Windows Desktop, automatically open the generated PDF
  if (Platform.isWindows) {
    try {
      await Process.run('cmd', ['/c', 'start', '', targetPath], runInShell: true);
    } catch (_) {}
  }
}
