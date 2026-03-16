import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions the app needs at startup.
  static Future<void> requestAll() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();
  }

  static Future<bool> hasCameraPermission() async {
    return (await Permission.camera.status).isGranted;
  }

  static Future<bool> hasPhotosPermission() async {
    return (await Permission.photos.status).isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> hasLocationPermission() async {
    return (await Permission.location.status).isGranted;
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}
