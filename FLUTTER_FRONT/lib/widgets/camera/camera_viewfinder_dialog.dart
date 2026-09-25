import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import 'camera_viewfinder_controller.dart';

class CameraViewfinderDialog extends StatefulWidget {
  final String batchId;

  const CameraViewfinderDialog({
    super.key,
    required this.batchId,
  });

  static Future<Uint8List?> show(BuildContext context, {required String batchId}) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CameraViewfinderDialog(batchId: batchId),
    );
  }

  @override
  State<CameraViewfinderDialog> createState() => _CameraViewfinderDialogState();
}

class _CameraViewfinderDialogState extends State<CameraViewfinderDialog> {
  late final String _viewType;
  bool _isInitializing = true;
  bool _isStreaming = false;
  String? _errorMessage;
  bool _showShutterFlash = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    if (kIsWeb) {
      final success = await CameraViewController.startStream(_viewType);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isStreaming = success;
          if (!success) {
            _errorMessage = 'Could not start live webcam stream. Click below to allow camera or open camera hardware directly.';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isStreaming = false;
          _errorMessage = 'Desktop/native mode active. Click below to access device camera.';
        });
      }
    }
  }

  @override
  void dispose() {
    CameraViewController.stopStream();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    if (!_isStreaming) {
      await _handleDeviceCameraPick();
      return;
    }

    // Visual shutter flash effect
    setState(() => _showShutterFlash = true);
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _showShutterFlash = false);

    final bytes = CameraViewController.captureSnapshot();
    if (bytes != null && bytes.isNotEmpty) {
      CameraViewController.stopStream();
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } else {
      // If snapshot from video element returned null, fall back to device camera picker
      await _handleDeviceCameraPick();
    }
  }

  Future<void> _handleDeviceCameraPick() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 92,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          CameraViewController.stopStream();
          Navigator.of(context).pop(bytes);
        }
        return;
      }
    } catch (e) {
      debugPrint('Device camera pick error: $e');
    }

    // Fallback: pick from device files/photos
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          CameraViewController.stopStream();
          Navigator.of(context).pop(bytes);
        }
      }
    } catch (e) {
      debugPrint('Gallery picker fallback error: $e');
    }
  }

  Future<void> _handleSamplePhoto() async {
    try {
      final data = await rootBundle.load('assets/images/sample_grid.jpg');
      final bytes = data.buffer.asUint8List();
      if (mounted) {
        CameraViewController.stopStream();
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      debugPrint('Sample asset load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 680 : double.infinity,
          maxHeight: 720,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP HEADER & INSTRUCTION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE CAMERA INSPECTION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            'Batch: ${widget.batchId} • Red Area Non-Overlapping Grid',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      CameraViewController.stopStream();
                      Navigator.of(context).pop(null);
                    },
                  ),
                ],
              ),
            ),

            // 2. MAIN CAMERA VIEWFINDER WINDOW WITH HUD
            Flexible(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video Stream Layer (Web HtmlElementView)
                      if (_isStreaming && kIsWeb)
                        HtmlElementView(viewType: _viewType)
                      else if (_isInitializing)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 14),
                              Text(
                                'Accessing camera hardware...',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_enhance_rounded, color: Color(0xFFEF4444), size: 42),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Ready to Access Camera',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage ?? 'Point camera at non-overlapping onions on tray.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 20),

                                // Access Action Buttons
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _handleDeviceCameraPick,
                                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                      label: const Text('OPEN CAMERA HARDWARE'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      ),
                                    ),
                                    if (kIsWeb)
                                      OutlinedButton.icon(
                                        onPressed: _initCamera,
                                        icon: const Icon(Icons.videocam_rounded, size: 18),
                                        label: const Text('CONNECT WEBCAM'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white38),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: _handleSamplePhoto,
                                      icon: const Icon(Icons.grid_on_rounded, size: 18),
                                      label: const Text('USE NON-OVERLAPPING SAMPLE'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: const BorderSide(color: Colors.white24),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // HUD Overlay: Reticle Crosshairs and Grid
                      if (_isStreaming) ...[
                        // Subtle grid lines
                        Opacity(
                          opacity: 0.12,
                          child: CustomPaint(
                            painter: _CameraGridPainter(),
                          ),
                        ),

                        // Corner Target Reticle
                        Center(
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: CustomPaint(
                              painter: _ReticleCornerPainter(),
                            ),
                          ),
                        ),

                        // Guidelines Banner
                        Positioned(
                          bottom: 12,
                          left: 20,
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ZERO OVERLAP SAMPLING BOUNDARY',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Space 10–30 onions with NO overlap',
                                    style: TextStyle(color: Colors.white70, fontSize: 9.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // White Shutter Flash
                      if (_showShutterFlash)
                        Container(color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

            // 3. BOTTOM SHUTTER CONTROLS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  TextButton.icon(
                    onPressed: () {
                      CameraViewController.stopStream();
                      Navigator.of(context).pop(null);
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Shutter Button (Capture) - ALWAYS functional!
                  GestureDetector(
                    onTap: _handleCapture,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Switch / Refresh camera feed
                  IconButton(
                    tooltip: 'Restart / Toggle Camera',
                    onPressed: _initCamera,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.8;

    const divisions = 3;
    for (int i = 1; i < divisions; i++) {
      final x = size.width * (i / divisions);
      final y = size.height * (i / divisions);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReticleCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 20.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
