// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';

html.VideoElement? _activeVideoElement;
html.MediaStream? _activeStream;
String? _registeredViewType;

class WebCameraManager {
  /// Starts camera video stream with cascading constraint fallbacks
  /// to ensure ANY available camera (rear phone, laptop webcam, USB cam) is accessed.
  static Future<bool> startStream({required String viewType}) async {
    try {
      stopStream();

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        debugPrint('Web mediaDevices API not available in this browser context.');
        return false;
      }

      html.MediaStream? stream;

      // Tier 1: Try environment (rear) camera with high resolution
      try {
        stream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': {'ideal': 'environment'},
            'width': {'ideal': 1920},
            'height': {'ideal': 1080},
          },
          'audio': false,
        });
      } catch (e1) {
        debugPrint('Tier 1 environment camera constraint failed: $e1');
      }

      // Tier 2: Try user/front camera (standard for laptops & tablets)
      if (stream == null) {
        try {
          stream = await mediaDevices.getUserMedia({
            'video': {
              'facingMode': {'ideal': 'user'},
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            },
            'audio': false,
          });
        } catch (e2) {
          debugPrint('Tier 2 user camera constraint failed: $e2');
        }
      }

      // Tier 3: Universal video fallback (any camera hardware attached)
      if (stream == null) {
        try {
          stream = await mediaDevices.getUserMedia({
            'video': true,
            'audio': false,
          });
        } catch (e3) {
          debugPrint('Tier 3 generic camera fallback failed: $e3');
        }
      }

      if (stream == null) {
        return false;
      }

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      video.srcObject = stream;
      _activeStream = stream;
      _activeVideoElement = video;

      if (_registeredViewType != viewType) {
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int id) => video,
        );
        _registeredViewType = viewType;
      }
      return true;
    } catch (e) {
      debugPrint('WebCam stream startup general error: $e');
      return false;
    }
  }

  /// Captures current frame from live video element as JPEG bytes
  static Uint8List? captureSnapshot() {
    if (_activeVideoElement == null) return null;
    final video = _activeVideoElement!;
    final vw = video.videoWidth > 0 ? video.videoWidth : 1280;
    final vh = video.videoHeight > 0 ? video.videoHeight : 720;

    final canvas = html.CanvasElement(width: vw, height: vh);
    final ctx = canvas.context2D;
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
    if (!dataUrl.contains(',')) return null;

    final base64String = dataUrl.split(',')[1];
    return base64Decode(base64String);
  }

  /// Stops all media stream tracks and resets video element
  static void stopStream() {
    if (_activeStream != null) {
      for (final track in _activeStream!.getTracks()) {
        track.stop();
      }
      _activeStream = null;
    }
    if (_activeVideoElement != null) {
      _activeVideoElement?.srcObject = null;
      _activeVideoElement = null;
    }
  }
}
