import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'log_service.dart';

class PermissionService {
  final LogService logService;
  int? _androidSdkVersion;

  PermissionService({required this.logService});

  /// Get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (_androidSdkVersion != null) {
      return _androidSdkVersion!;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;
      logService.info('Android SDK Version: $_androidSdkVersion');
      return _androidSdkVersion!;
    }
    return 0;
  }

  /// Request storage permissions for video access
  Future<bool> requestStoragePermissions() async {
    try {
      logService.info('Requesting storage permissions');

      if (!Platform.isAndroid) {
        logService.info('Not Android platform, permissions granted by default');
        return true;
      }

      final sdkVersion = await _getAndroidSdkVersion();
      final List<Permission> permissionsToRequest = [];

      // Android 13+ (API 33+) uses granular media permissions
      if (sdkVersion >= 33) {
        permissionsToRequest.add(Permission.videos);
        permissionsToRequest.add(Permission.photos); // For thumbnails
        logService.info('Requesting Android 13+ media permissions (videos, photos)');
      } else {
        // Android 12 and below use READ_EXTERNAL_STORAGE
        permissionsToRequest.add(Permission.storage);
        logService.info('Requesting Android 12- storage permission');
      }

      final Map<Permission, PermissionStatus> statuses =
          await permissionsToRequest.request();

      // Log permission results
      statuses.forEach((permission, status) {
        logService.info('Permission $permission: $status');
      });

      // Check if any required permission is granted
      bool granted = false;
      if (sdkVersion >= 33) {
        granted = (statuses[Permission.videos]?.isGranted ?? false);
      } else {
        granted = (statuses[Permission.storage]?.isGranted ?? false);
      }

      if (granted) {
        logService.info('Storage permissions granted');
      } else {
        logService.warning('Storage permissions denied');
        
        // Check if permanently denied
        if (sdkVersion >= 33) {
          if (statuses[Permission.videos]?.isPermanentlyDenied ?? false) {
            logService.warning('Videos permission permanently denied');
          }
        } else {
          if (statuses[Permission.storage]?.isPermanentlyDenied ?? false) {
            logService.warning('Storage permission permanently denied');
          }
        }
      }

      return granted;
    } catch (e, stackTrace) {
      logService.error('Error requesting storage permissions', error: e);
      logService.debug('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    try {
      if (!Platform.isAndroid) {
        return true;
      }

      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        // Android 13+: check videos permission
        final videosStatus = await Permission.videos.status;
        logService.debug('Videos permission status: $videosStatus');
        return videosStatus.isGranted;
      } else {
        // Android 12 and below: check storage permission
        final storageStatus = await Permission.storage.status;
        logService.debug('Storage permission status: $storageStatus');
        return storageStatus.isGranted;
      }
    } catch (e, stackTrace) {
      logService.error('Error checking storage permissions', error: e);
      logService.debug('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if permissions are permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }

      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        final videosStatus = await Permission.videos.status;
        return videosStatus.isPermanentlyDenied;
      } else {
        final storageStatus = await Permission.storage.status;
        return storageStatus.isPermanentlyDenied;
      }
    } catch (e) {
      logService.error('Error checking if permission permanently denied', error: e);
      return false;
    }
  }

  /// Ensure the app has storage permissions, requesting them if necessary
  Future<bool> ensureStoragePermissions() async {
    final hasPermissions = await hasStoragePermissions();
    if (hasPermissions) {
      logService.debug('Storage permissions already granted');
      return true;
    }

    logService.info('Storage permissions not granted, requesting...');
    final granted = await requestStoragePermissions();
    
    if (!granted) {
      logService.warning('Storage permissions not granted after request');
      
      // Check if permanently denied
      final permanentlyDenied = await isPermissionPermanentlyDenied();
      if (permanentlyDenied) {
        logService.warning('Storage permissions permanently denied, user needs to enable in settings');
      }
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
