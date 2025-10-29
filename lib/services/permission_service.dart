import 'package:permission_handler/permission_handler.dart';
import 'log_service.dart';

class PermissionService {
  final LogService logService;

  PermissionService({required this.logService});

  /// Request storage permissions for video access
  Future<bool> requestStoragePermissions() async {
    try {
      logService.info('Requesting storage permissions');

      // For Android 13+ (API 33+), use READ_MEDIA_VIDEO
      // For older versions, use READ_EXTERNAL_STORAGE
      // Request both and let the system handle which one to use
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.videos,
        Permission.storage,
      ].request();

      final videosGranted = statuses[Permission.videos]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      final granted = videosGranted || storageGranted;

      if (granted) {
        logService.info('Storage permissions granted');
      } else {
        logService.warning('Storage permissions denied');
      }

      return granted;
    } catch (e) {
      logService.error('Error requesting storage permissions', error: e);
      return false;
    }
  }

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    try {
      final videosStatus = await Permission.videos.status;
      final storageStatus = await Permission.storage.status;

      return videosStatus.isGranted || storageStatus.isGranted;
    } catch (e) {
      logService.error('Error checking storage permissions', error: e);
      return false;
    }
  }

  /// Open app settings for manual permission grant
  Future<bool> openSettings() async {
    try {
      logService.info('Opening app settings');
      return await openAppSettings();
    } catch (e) {
      logService.error('Error opening app settings', error: e);
      return false;
    }
  }
}
