import 'package:permission_handler/permission_handler.dart';
import 'log_service.dart';

class PermissionService {
  final LogService logService;

  PermissionService({required this.logService});

  /// Request storage permissions for video access
  Future<bool> requestStoragePermissions() async {
    try {
      logService.info('Requesting storage permissions');

      // Try to request permissions one by one to avoid issues
      bool granted = false;
      
      // Try videos permission first (Android 13+)
      try {
        final videosStatus = await Permission.videos.request();
        if (videosStatus.isGranted) {
          logService.info('Videos permission granted');
          granted = true;
        }
      } catch (e) {
        logService.warning('Videos permission not available: $e');
      }

      // Try storage permission (Android 12 and below)
      if (!granted) {
        try {
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted) {
            logService.info('Storage permission granted');
            granted = true;
          }
        } catch (e) {
          logService.warning('Storage permission not available: $e');
        }
      }

      // Try manage external storage (Android 11+)
      if (!granted) {
        try {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (manageStatus.isGranted) {
            logService.info('Manage external storage permission granted');
            granted = true;
          } else {
            logService.warning('Manage external storage permission denied or not available');
          }
        } catch (e) {
          logService.warning('Manage external storage permission not available: $e');
        }
      }

      if (granted) {
        logService.info('Storage permissions granted');
      } else {
        logService.warning('All storage permissions denied or unavailable');
      }

      return granted;
    } catch (e, stackTrace) {
      logService.error('Error requesting storage permissions: $e\nStackTrace: $stackTrace', error: e);
      return false;
    }
  }

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    try {
      // Check each permission individually to avoid issues
      bool hasPermission = false;

      // Check videos permission (Android 13+)
      try {
        final videosStatus = await Permission.videos.status;
        if (videosStatus.isGranted) {
          logService.info('Videos permission is granted');
          hasPermission = true;
        }
      } catch (e) {
        logService.warning('Cannot check videos permission: $e');
      }

      // Check storage permission (Android 12 and below)
      if (!hasPermission) {
        try {
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) {
            logService.info('Storage permission is granted');
            hasPermission = true;
          }
        } catch (e) {
          logService.warning('Cannot check storage permission: $e');
        }
      }

      // Check manage external storage (Android 11+)
      if (!hasPermission) {
        try {
          final manageStorageStatus = await Permission.manageExternalStorage.status;
          if (manageStorageStatus.isGranted) {
            logService.info('Manage external storage permission is granted');
            hasPermission = true;
          }
        } catch (e) {
          logService.warning('Cannot check manage external storage permission: $e');
        }
      }

      return hasPermission;
    } catch (e, stackTrace) {
      logService.error('Error checking storage permissions: $e\nStackTrace: $stackTrace', error: e);
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
