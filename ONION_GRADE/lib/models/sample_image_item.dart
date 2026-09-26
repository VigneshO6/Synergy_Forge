import 'dart:typed_data';
import 'package:flutter/material.dart';

class SampleImageItem {
  final String id;
  final String? assetPath;
  final Uint8List? bytes;
  final String name;
  final DateTime capturedAt;

  SampleImageItem({
    required this.id,
    this.assetPath,
    this.bytes,
    required this.name,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  bool get isMemory => bytes != null;
  bool get isAsset => assetPath != null;

  Widget buildThumbnail({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorPlaceholder(width, height),
      );
    } else if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorPlaceholder(width, height),
      );
    }
    return _errorPlaceholder(width, height);
  }

  Widget _errorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.15),
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
      ),
    );
  }
}
