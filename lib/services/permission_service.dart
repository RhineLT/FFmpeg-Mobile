import 'dart:io';
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
      final List<Permission> permissionsToRequest = [
        Permission.videos,
        Permission.storage,
        Permission.audio,
      ];

      if (Platform.isAndroid) {
        // MANAGE_EXTERNAL_STORAGE is needed to write to shared storage on API 30+
        permissionsToRequest.add(Permission.manageExternalStorage);
      }

      final Map<Permission, PermissionStatus> statuses =
          await permissionsToRequest.request();

      final videosGranted = statuses[Permission.videos]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
      final manageGranted =
          statuses[Permission.manageExternalStorage]?.isGranted ?? false;

      final granted =
          videosGranted || storageGranted || audioGranted || manageGranted;

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
      final audioStatus = await Permission.audio.status;
      PermissionStatus? manageStatus;
      if (Platform.isAndroid) {
        manageStatus = await Permission.manageExternalStorage.status;
      }

      return videosStatus.isGranted ||
          storageStatus.isGranted ||
          audioStatus.isGranted ||
          (manageStatus?.isGranted ?? false);
    } catch (e) {
      logService.error('Error checking storage permissions', error: e);
      return false;
    }
  }

  /// Ensure the app has storage permissions, requesting them if necessary
  Future<bool> ensureStoragePermissions() async {
    final hasPermissions = await hasStoragePermissions();
    if (hasPermissions) {
      return true;
    }

    final granted = await requestStoragePermissions();
    if (!granted) {
      logService.warning('Storage permissions not granted after request');
    }
    return granted;
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
