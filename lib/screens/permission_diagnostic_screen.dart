import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限诊断页面 - 显示所有权限状态
class PermissionDiagnosticScreen extends StatefulWidget {
  const PermissionDiagnosticScreen({super.key});

  @override
  State<PermissionDiagnosticScreen> createState() => _PermissionDiagnosticScreenState();
}

class _PermissionDiagnosticScreenState extends State<PermissionDiagnosticScreen> {
  Map<String, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isLoading = true);
    
    final statuses = <String, PermissionStatus>{};
    
    // Check each permission individually
    try {
      statuses['Videos (READ_MEDIA_VIDEO)'] = await Permission.videos.status;
    } catch (e) {
      debugPrint('Error checking videos permission: $e');
    }
    
    try {
      statuses['Storage (READ_EXTERNAL_STORAGE)'] = await Permission.storage.status;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
    }
    
    try {
      statuses['Manage Storage (MANAGE_EXTERNAL_STORAGE)'] = await Permission.manageExternalStorage.status;
    } catch (e) {
      debugPrint('Error checking manage storage permission: $e');
    }

    setState(() {
      _permissionStatuses = statuses;
      _isLoading = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    // Request permissions one by one
    try {
      await Permission.videos.request();
    } catch (e) {
      debugPrint('Error requesting videos permission: $e');
    }
    
    try {
      await Permission.storage.request();
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
    }
    
    try {
      await Permission.manageExternalStorage.request();
    } catch (e) {
      debugPrint('Error requesting manage storage permission: $e');
    }

    await _checkAllPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限诊断'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '权限状态检查',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '此页面显示应用所需的所有权限状态',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._permissionStatuses.entries.map((entry) {
                  final isGranted = entry.value.isGranted;
                  final isPermanentlyDenied = entry.value.isPermanentlyDenied;
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isGranted ? Icons.check_circle : Icons.cancel,
                        color: isGranted ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(entry.key),
                      subtitle: Text(_getStatusText(entry.value)),
                      trailing: isPermanentlyDenied
                          ? TextButton(
                              onPressed: openAppSettings,
                              child: const Text('打开设置'),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _requestAllPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('请求所有权限'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('打开系统设置'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                const Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '注意事项',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Android 13+: 需要 "照片和视频" 权限\n'
                          '• Android 11-12: 建议授予 "管理所有文件" 权限\n'
                          '• Android 10-: 需要 "存储" 权限',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✓ 已授予';
      case PermissionStatus.denied:
        return '✗ 已拒绝';
      case PermissionStatus.restricted:
        return '⚠ 受限制';
      case PermissionStatus.limited:
        return '⚠ 有限访问';
      case PermissionStatus.permanentlyDenied:
        return '✗ 永久拒绝 (需要手动设置)';
      case PermissionStatus.provisional:
        return '⚠ 临时授权';
    }
  }
}
