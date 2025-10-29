import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  final PermissionService permissionService;
  final VoidCallback onPermissionGranted;

  const PermissionScreen({
    super.key,
    required this.permissionService,
    required this.onPermissionGranted,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    // Automatically request permission on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermission();
    });
  }

  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final granted = await widget.permissionService.requestStoragePermissions();
      
      if (mounted) {
        if (granted) {
          widget.onPermissionGranted();
        } else {
          setState(() {
            _isRequesting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await widget.permissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.video_library,
                  size: 60,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                '需要访问权限',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'FFmpeg-Mobile 需要访问您的视频文件以进行压缩处理。\n\n'
                '我们承诺：\n'
                '• 仅访问您选择的视频文件\n'
                '• 不会上传或分享您的视频\n'
                '• 所有处理都在本地完成',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Permission items
              _buildPermissionItem(
                icon: Icons.video_file,
                title: '视频访问',
                description: '读取和处理您的视频文件',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.folder,
                title: '文件存储',
                description: '保存压缩后的视频文件',
              ),
              const SizedBox(height: 40),

              // Request button
              if (_isRequesting)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '正在请求权限...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '授予权限',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _openSettings,
                      child: const Text(
                        '前往设置手动授权',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
