# 权限错误排查和修复

## 问题分析

从日志中发现的错误：
1. ✗ Error checking storage permissions（权限检查失败）
2. ✗ Storage permission denied（权限被拒绝）
3. ✗ Error requesting storage permissions（权限请求失败）
4. ✗ Failed to get default output directory（获取默认输出目录失败）
5. ✗ Failed to resolve default output directory（无法解析输出目录）

## 根本原因

### 1. 权限请求方式问题

**原来的代码：**
```dart
// 批量请求所有权限
final Map<Permission, PermissionStatus> statuses = await [
  Permission.videos,
  Permission.storage,
  Permission.manageExternalStorage,
].request();
```

**问题：**
- 在某些 Android 版本上，某些权限可能不存在
- 批量请求时，如果一个权限抛出异常，整个请求都会失败
- 没有详细的错误日志，难以定位具体哪个权限有问题

### 2. 输出目录获取逻辑脆弱

**原来的代码：**
```dart
final externalDir = await getExternalStorageDirectory();
if (externalDir != null) {
  // 使用外部存储
}
// 如果失败就返回 null
```

**问题：**
- 没有充分的错误处理
- 没有详细日志说明失败原因
- 没有多层回退机制

## 修复方案

### 1. PermissionService 改进

#### 权限请求（逐个处理）

```dart
Future<bool> requestStoragePermissions() async {
  try {
    logService.info('Requesting storage permissions');
    bool granted = false;
    
    // 1. 尝试 videos 权限（Android 13+）
    try {
      final videosStatus = await Permission.videos.request();
      if (videosStatus.isGranted) {
        logService.info('Videos permission granted');
        granted = true;
      }
    } catch (e) {
      logService.warning('Videos permission not available: $e');
    }

    // 2. 尝试 storage 权限（Android 12-）
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

    // 3. 尝试 manage external storage（Android 11+）
    if (!granted) {
      try {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) {
          logService.info('Manage external storage permission granted');
          granted = true;
        }
      } catch (e) {
        logService.warning('Manage external storage permission not available: $e');
      }
    }

    return granted;
  } catch (e, stackTrace) {
    logService.error('Error requesting storage permissions: $e', error: e);
    return false;
  }
}
```

**优势：**
- ✅ 每个权限单独处理，一个失败不影响其他
- ✅ 详细的日志，可以看到具体哪个权限有问题
- ✅ 按优先级尝试，一旦成功就停止
- ✅ 捕获每个步骤的异常

#### 权限检查（同样逐个处理）

```dart
Future<bool> hasStoragePermissions() async {
  try {
    bool hasPermission = false;

    // 逐个检查每个权限
    try {
      final videosStatus = await Permission.videos.status;
      if (videosStatus.isGranted) {
        logService.info('Videos permission is granted');
        hasPermission = true;
      }
    } catch (e) {
      logService.warning('Cannot check videos permission: $e');
    }

    // ... 同样处理其他权限

    return hasPermission;
  } catch (e, stackTrace) {
    logService.error('Error checking storage permissions: $e', error: e);
    return false;
  }
}
```

### 2. TaskManager 初始化改进

#### 详细的初始化日志

```dart
Future<void> init() async {
  if (_initialized) {
    logService.info('TaskManager already initialized');
    return;
  }

  try {
    // 每个步骤都有日志
    logService.info('Loading saved tasks...');
    final savedTasks = await storageService.loadTasks();
    _tasks.addAll(savedTasks);
    logService.info('Loaded ${savedTasks.length} saved tasks');

    logService.info('Loading compression settings...');
    _compressionSettings = await storageService.loadCompressionSettings();
    logService.info('Compression settings loaded');

    logService.info('Loading output directory...');
    _outputDirectory = await storageService.loadOutputDirectory();
    
    if (_outputDirectory == null) {
      logService.info('No saved output directory, getting default...');
      _outputDirectory = await _getDefaultOutputDirectory();
      if (_outputDirectory != null) {
        logService.info('Default output directory set: $_outputDirectory');
      } else {
        logService.warning('Failed to resolve default output directory');
      }
    }

    _initialized = true;
    logService.info('Task manager initialized successfully');
  } catch (e, stackTrace) {
    logService.error('Failed to initialize TaskManager: $e', error: e);
    _initialized = true; // 即使失败也标记为已初始化，允许应用继续
    rethrow;
  }
}
```

#### 改进的输出目录获取

```dart
Future<String?> _getDefaultOutputDirectory() async {
  try {
    logService.info('Getting default output directory...');
    
    if (Platform.isAndroid) {
      // 尝试外部存储
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          logService.info('External storage: ${externalDir.path}');
          final outputDir = Directory(
            path.join(externalDir.path, 'Movies', 'FFmpeg-Mobile'),
          );
          await outputDir.create(recursive: true);
          logService.info('Using external storage: ${outputDir.path}');
          return outputDir.path;
        }
      } catch (e) {
        logService.warning('External storage failed: $e');
      }

      // 回退到内部存储
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        logService.info('Documents directory: ${docsDir.path}');
        final internalDir = Directory(
          path.join(docsDir.path, 'Movies', 'FFmpeg-Mobile'),
        );
        await internalDir.create(recursive: true);
        logService.info('Using internal storage: ${internalDir.path}');
        return internalDir.path;
      } catch (e) {
        logService.error('Documents directory failed: $e', error: e);
      }
    }
  } catch (e, stackTrace) {
    logService.error('Failed to get default output directory: $e', error: e);
  }
  
  return null;
}
```

### 3. 新增权限诊断页面

创建了 `PermissionDiagnosticScreen`，提供：

1. **可视化权限状态**
   - 显示每个权限的当前状态（已授予/已拒绝/永久拒绝等）
   - 使用颜色和图标直观显示

2. **一键请求所有权限**
   - 点击按钮请求所有需要的权限
   - 自动刷新状态

3. **快速打开系统设置**
   - 对于永久拒绝的权限，提供快捷入口
   - 一键打开应用设置页面

4. **使用说明**
   - 显示不同 Android 版本的权限要求
   - 提供清晰的操作指引

#### 访问方式

在主界面点击工具栏的 🛡️ 盾牌图标即可打开权限诊断页面。

## 修复效果对比

### 修复前的日志

```
[21:53:26] [INFO] Requesting storage permissions
[21:53:26] [ERROR] Error checking storage permissions
[21:53:25] [ERROR] Storage permission denied
[21:53:25] [ERROR] Error requesting storage permissions
[21:53:24] [ERROR] Failed to resolve default output directory
[21:53:24] [ERROR] Failed to get default output directory
```

### 修复后的预期日志

```
[INFO] Loading saved tasks...
[INFO] Loaded 0 saved tasks
[INFO] Loading compression settings...
[INFO] Compression settings loaded: -hwaccel auto -c:v libx265...
[INFO] Loading output directory...
[INFO] No saved output directory, getting default...
[INFO] Getting default output directory...
[INFO] External storage directory: /storage/emulated/0/Android/data/.../files
[INFO] Using external storage output directory: .../Movies/FFmpeg-Mobile
[INFO] Default output directory set: .../Movies/FFmpeg-Mobile
[INFO] Task manager initialized successfully with 0 tasks
```

如果权限请求时：
```
[INFO] Requesting storage permissions
[INFO] Videos permission granted
[INFO] Storage permissions granted
```

或者如果某个权限不可用：
```
[INFO] Requesting storage permissions
[WARNING] Videos permission not available: ...
[INFO] Storage permission granted
[INFO] Storage permissions granted
```

## 测试流程

### 1. 完整测试（推荐）

```bash
# 清理并重新构建
flutter clean
flutter pub get
flutter build apk --debug

# 完全卸载旧版本
adb uninstall com.videocompressor.video_compressor

# 安装新版本
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 启动应用
adb shell am start -n com.videocompressor.video_compressor/.MainActivity

# 查看日志
adb logcat -c
adb logcat | grep -E "flutter|FFmpeg"
```

### 2. 使用权限诊断

1. 启动应用后，点击工具栏的 🛡️ 图标
2. 查看所有权限状态
3. 点击"请求所有权限"按钮
4. 对于永久拒绝的权限，点击"打开设置"手动授予

### 3. 验证功能

1. ✅ 应用能正常启动（不再白屏）
2. ✅ 初始化日志清晰完整
3. ✅ 权限请求不再报错
4. ✅ 能够选择视频文件
5. ✅ 能够设置输出目录
6. ✅ 压缩功能正常工作

## 关键改进总结

| 方面 | 修复前 | 修复后 |
|------|--------|--------|
| 权限请求 | 批量请求，一个失败全部失败 | 逐个请求，容错性强 |
| 错误日志 | 简单的错误提示 | 详细的步骤日志 |
| 输出目录 | 单一尝试，失败即停 | 多层回退机制 |
| 用户体验 | 只能看错误日志 | 可视化诊断页面 |
| 调试能力 | 难以定位问题 | 清晰的步骤追踪 |

## 下一步建议

1. **测试应用**
   - 在实际设备上测试权限流程
   - 验证不同 Android 版本的兼容性

2. **收集反馈**
   - 使用权限诊断页面查看状态
   - 检查日志中的详细信息

3. **可能的优化**
   - 添加首次启动引导
   - 添加权限说明对话框
   - 优化权限请求时机

现在应该可以正常使用了！🎉
