import 'package:flutter/material.dart';
import '../services/ocr_service.dart';

class ScreenshotScanner extends StatefulWidget {
  final ValueChanged<String> onTextExtracted;

  const ScreenshotScanner({super.key, required this.onTextExtracted});

  @override
  State<ScreenshotScanner> createState() => _ScreenshotScannerState();
}

class _ScreenshotScannerState extends State<ScreenshotScanner> {
  final _ocr = OcrService();
  bool _processing = false;
  String? _extractedText;
  String? _error;

  Future<void> _scan({required bool fromCamera}) async {
    setState(() {
      _processing = true;
      _error = null;
      _extractedText = null;
    });

    try {
      final text = fromCamera
          ? await _ocr.pickAndScanFromCamera()
          : await _ocr.pickAndScanFromGallery();

      if (text == null) {
        setState(() {
          _processing = false;
          _error = 'No text detected in the image.';
        });
        return;
      }

      setState(() {
        _processing = false;
        _extractedText = text;
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Failed to scan image: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Scan Screenshot',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_processing) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Center(child: Text('Extracting text from image...')),
            const SizedBox(height: 40),
          ] else if (_extractedText != null) ...[
            Text(
              'Extracted Text:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(_extractedText!),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                widget.onTextExtracted(_extractedText!);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.search),
              label: const Text('Analyze This Text'),
            ),
          ] else ...[
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scan(fromCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scan(fromCamera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
