import 'package:flutter/foundation.dart';

import 'camera_viewfinder_stub.dart'
    if (dart.library.html) 'camera_viewfinder_web.dart';

class CameraViewController {
  static Future<bool> startStream(String viewType) async {
    if (kIsWeb) {
      return await WebCameraManager.startStream(viewType: viewType);
    }
    return false;
  }

  static Uint8List? captureSnapshot() {
    if (kIsWeb) {
      return WebCameraManager.captureSnapshot();
    }
    return null;
  }

  static void stopStream() {
    if (kIsWeb) {
      WebCameraManager.stopStream();
    }
  }
}
