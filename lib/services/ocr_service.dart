import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'permission_service.dart';

/// Return codes that the ScreenshotScanner uses to show the right message.
enum OcrPickResult {
  /// User dismissed the picker or permission was denied.
  cancelled,

  /// A file was selected but no readable text was found.
  noText,

  /// Text was successfully extracted.
  success,
}

class OcrScanResult {
  final OcrPickResult result;
  final String? text;
  final bool permissionDenied;

  const OcrScanResult({
    required this.result,
    this.text,
    this.permissionDenied = false,
  });
}

class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery and extract text.
  /// [image_picker] handles Android storage/media permissions internally,
  /// so we do NOT pre-check permissions here — that was blocking the picker
  /// on devices where permission_handler incorrectly reported denial.
  Future<OcrScanResult> pickAndScanFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      // null means user cancelled OR permission was silently denied.
      // Post-check to distinguish the two cases.
      final hasPermission = await PermissionService.hasPhotosPermission();
      return OcrScanResult(
        result: OcrPickResult.cancelled,
        permissionDenied: !hasPermission,
      );
    }
    return _extractText(File(file.path));
  }

  /// Pick an image from the camera and extract text.
  Future<OcrScanResult> pickAndScanFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) {
      final hasPermission = await PermissionService.hasCameraPermission();
      return OcrScanResult(
        result: OcrPickResult.cancelled,
        permissionDenied: !hasPermission,
      );
    }
    return _extractText(File(file.path));
  }

  /// Extract text from an image file using ML Kit.
  Future<OcrScanResult> _extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      if (text.isEmpty) {
        return const OcrScanResult(result: OcrPickResult.noText);
      }
      return OcrScanResult(result: OcrPickResult.success, text: text);
    } finally {
      textRecognizer.close();
    }
  }
}
