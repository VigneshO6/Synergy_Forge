import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/quality_model.dart';
import '../models/sample_image_item.dart';
import '../services/analysis_service.dart';
import '../services/demo_analysis_service.dart';
import '../services/api_analysis_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final DemoImageAnalysisService _demoService = DemoImageAnalysisService();
  late ApiImageAnalysisService _apiService;
  final ImagePicker _picker = ImagePicker();

  bool _isDemoMode = false;
  String _apiBaseUrl = 'http://127.0.0.1:8000';

  // Configurable Quality Thresholds (Strict 4-Class System)
  double _goodThreshold = 75.0;
  double _defectTolerance = 10.0;

  // Selected sample images for the active batch
  final List<SampleImageItem> _sampleItems = [];

  bool _isAnalyzing = false;
  String _currentStepMessage = '';
  double _currentProgress = 0.0;
  QualityAnalysisResult? _currentResult;
  String? _errorMessage;

  AnalysisProvider() {
    _apiService = ApiImageAnalysisService(baseUrl: _apiBaseUrl);
  }

  bool get isDemoMode => _isDemoMode;
  String get apiBaseUrl => _apiBaseUrl;
  double get goodThreshold => _goodThreshold;
  double get defectTolerance => _defectTolerance;
  List<SampleImageItem> get sampleItems => List.unmodifiable(_sampleItems);
  List<String> get sampleImages => _sampleItems.map((e) => e.assetPath ?? e.name).toList();
  bool get isAnalyzing => _isAnalyzing;
  String get currentStepMessage => _currentStepMessage;
  double get currentProgress => _currentProgress;
  QualityAnalysisResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;

  ImageAnalysisService get currentService =>
      _isDemoMode ? _demoService : _apiService;

  void toggleDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  void setApiBaseUrl(String url) {
    _apiBaseUrl = url;
    _apiService = ApiImageAnalysisService(baseUrl: _apiBaseUrl);
    notifyListeners();
  }

  void updateThresholds({required double good, double? defectTolerance}) {
    _goodThreshold = good;
    if (defectTolerance != null) _defectTolerance = defectTolerance;
    notifyListeners();
  }

  void addSampleBytes(Uint8List bytes, {String? name}) {
    final newItem = SampleImageItem(
      id: 'cam-${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      name: name ?? 'Live_Camera_${_sampleItems.length + 1}.jpg',
    );
    _sampleItems.add(newItem);
    notifyListeners();
  }

  // Real Camera Capture
  Future<bool> captureWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final newItem = SampleImageItem(
          id: 'cam-${DateTime.now().millisecondsSinceEpoch}',
          bytes: bytes,
          name: photo.name.isNotEmpty ? photo.name : 'Camera_Sample_${_sampleItems.length + 1}.jpg',
        );
        _sampleItems.add(newItem);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Camera access error: $e');
    }
    return false;
  }

  // Real Gallery Single/Multi Pick
  Future<bool> pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        for (final img in images) {
          final bytes = await img.readAsBytes();
          _sampleItems.add(
            SampleImageItem(
              id: 'gal-${DateTime.now().millisecondsSinceEpoch}-${img.name}',
              bytes: bytes,
              name: img.name,
            ),
          );
        }
        notifyListeners();
        return true;
      } else {
        // Fallback for platforms that only support single pick
        final XFile? single = await _picker.pickImage(source: ImageSource.gallery);
        if (single != null) {
          final bytes = await single.readAsBytes();
          _sampleItems.add(
            SampleImageItem(
              id: 'gal-${DateTime.now().millisecondsSinceEpoch}',
              bytes: bytes,
              name: single.name,
            ),
          );
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
    }
    return false;
  }

  void addAssetSample(String assetPath, String name) {
    _sampleItems.add(
      SampleImageItem(
        id: 'asset-${DateTime.now().millisecondsSinceEpoch}',
        assetPath: assetPath,
        name: name,
      ),
    );
    notifyListeners();
  }

  void removeSampleItem(int index) {
    if (index >= 0 && index < _sampleItems.length) {
      _sampleItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearSamples() {
    _sampleItems.clear();
    notifyListeners();
  }

  void resetSamples() {
    clearSamples();
  }

  Future<QualityAnalysisResult?> runAnalysis(String batchId) async {
    if (_sampleItems.isEmpty) {
      _errorMessage = 'Please capture or select at least 1 representative sample image.';
      notifyListeners();
      return null;
    }

    _isAnalyzing = true;
    _errorMessage = null;
    _currentProgress = 0.05;
    _currentStepMessage = 'Initializing vision inspection pipeline...';
    notifyListeners();

    try {
      final paths = sampleImages;
      final activeItem = _sampleItems.isNotEmpty ? _sampleItems.first : null;
      final result = await currentService.analyzeSamples(
        batchId: batchId,
        imagePaths: paths,
        sampleBytes: activeItem?.bytes,
        onProgress: (stepMessage, progress) {
          _currentStepMessage = stepMessage;
          _currentProgress = progress;
          notifyListeners();
        },
      );

      _currentResult = result;
      _isAnalyzing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isAnalyzing = false;
      _errorMessage = 'Quality analysis error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  void clearCurrentResult() {
    _currentResult = null;
    _currentStepMessage = '';
    _currentProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
