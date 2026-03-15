import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'permission_service.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery and extract text.
  Future<String?> pickAndScanFromGallery() async {
    final granted = await PermissionService.requestPhotos();
    if (!granted) return null;
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return _extractText(File(file.path));
  }

  /// Pick an image from the camera and extract text.
  Future<String?> pickAndScanFromCamera() async {
    final granted = await PermissionService.requestCamera();
    if (!granted) return null;
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return _extractText(File(file.path));
  }

  /// Extract text from an image file using ML Kit.
  Future<String?> _extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      textRecognizer.close();
    }
  }
}
