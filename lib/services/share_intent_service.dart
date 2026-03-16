import 'dart:async';
import 'package:flutter/services.dart';

/// Bridges the Android share-intent MethodChannel to Dart.
///
/// Usage:
///   final text = await ShareIntentService.instance.getInitialSharedText();
///   ShareIntentService.instance.sharedTextStream.listen((text) { … });
class ShareIntentService {
  ShareIntentService._();
  static final instance = ShareIntentService._();

  static const _channel = MethodChannel('com.example.scam_radar/share');

  final _streamController = StreamController<String>.broadcast();

  /// A broadcast stream that emits shared text when the app receives a new
  /// share intent while already running (via onNewIntent).
  Stream<String> get sharedTextStream => _streamController.stream;

  /// Call once at startup. Returns the shared text if the app was launched via
  /// a share intent, or null otherwise.
  Future<String?> getInitialSharedText() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _streamController.add(text);
        }
      }
    });
    try {
      return await _channel.invokeMethod<String>('getSharedText');
    } catch (_) {
      return null;
    }
  }

  void dispose() => _streamController.close();
}
