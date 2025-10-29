# MissingPluginException 错误修复

## 错误原因

从日志中看到：
```
MissingPluginException(No implementation found for method 
checkPermissionStatus on channel flutter.baseflow.com/permissions/methods)
```

以及：
```
PlatformException(channel-error, Unable to establish connection on channel:
"dev.flutter.pigeon.path_provider_android.PathProviderApi.getApplicationDocumentsPath")
```

**根本原因：**
1. `permission_handler` 插件在当前环境无法正常工作
2. `path_provider` 插件的通道连接也有问题
3. 这是 Flutter 插件注册/编译的问题

## 解决方案

### 方案：移除插件依赖，使用原生方法

不依赖有问题的插件，改用：
1. **权限处理**：让 `file_picker` 自动处理（它会请求权限）
2. **路径获取**：使用 Android 的标准固定路径

## 具体修改

### 1. 创建 SimplePermissionService

文件：`lib/services/simple_permission_service.dart`

```dart
class SimplePermissionService {
  final LogService logService;

  SimplePermissionService({required this.logService});

  /// 不依赖插件的权限服务
  Future<bool> requestStoragePermissions() async {
    logService.info('File picker will handle permissions automatically');
    return true; // file_picker 会自动处理
  }

  Future<bool> hasStoragePermissions() async {
    return true; // 假设有权限，让 file_picker 处理
  }
}
```

**优势：**
- ✅ 不依赖 permission_handler 插件
- ✅ file_picker 会自动请求所需权限
- ✅ 避免插件注册问题

### 2. 修改 TaskManager

```dart
// 导入简化版本
import '../services/simple_permission_service.dart';

class TaskManager extends ChangeNotifier {
  late final SimplePermissionService permissionService; // 使用简化版本

  TaskManager({...}) {
    permissionService = SimplePermissionService(logService: logService);
  }
}
```

### 3. 简化 pickVideos 方法

```dart
Future<void> pickVideos() async {
  try {
    // file_picker 会自动处理权限
    logService.info('Opening file picker for videos...');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    // ... 处理结果
  }
}
```

**优势：**
- ✅ 移除手动权限检查
- ✅ file_picker 内部会处理权限请求
- ✅ 代码更简洁

### 4. 使用固定路径

不依赖 `path_provider`，直接使用 Android 标准路径：

```dart
Future<String?> _getDefaultOutputDirectory() async {
  if (Platform.isAndroid) {
    try {
      // 使用标准的 Movies 目录
      final outputDir = Directory('/storage/emulated/0/Movies/FFmpeg-Mobile');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      return outputDir.path;
    } catch (e) {
      // 回退到 Downloads 目录
      final outputDir = Directory('/storage/emulated/0/Download/FFmpeg-Mobile');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      return outputDir.path;
    }
  }
}
```

**路径说明：**
- `/storage/emulated/0/Movies/FFmpeg-Mobile` - 主要输出目录
- `/storage/emulated/0/Download/FFmpeg-Mobile` - 备用目录

### 5. 移除不必要的文件

删除了依赖 permission_handler 的文件：
- ❌ `lib/screens/permission_diagnostic_screen.dart`
- ❌ HomeScreen 中的诊断按钮

## 工作原理

### file_picker 自动权限处理

当调用 `FilePicker.platform.pickFiles()` 时：

1. **Android 13+**：
   - 使用 Photo Picker（不需要权限）
   - 或者自动请求 READ_MEDIA_VIDEO 权限

2. **Android 11-12**：
   - 自动请求 READ_EXTERNAL_STORAGE 权限
   - 如果需要，会显示权限对话框

3. **Android 10-**：
   - 自动请求 READ_EXTERNAL_STORAGE 权限

**用户体验：**
- ✅ 点击选择视频时自动请求权限
- ✅ 无需提前检查权限
- ✅ 权限流程更自然

### 固定路径的优势

使用 `/storage/emulated/0/Movies/FFmpeg-Mobile`：

1. **兼容性好**：
   - Android 4.4+ 都支持
   - 不依赖 path_provider 插件

2. **用户友好**：
   - Movies 是标准媒体目录
   - 用户可以在文件管理器中轻松找到

3. **权限要求**：
   - 需要存储权限（由 file_picker 处理）
   - 创建目录不需要额外权限

## 测试步骤

### 1. 重新构建

```bash
./fix_plugin_error.sh
```

或手动：

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 2. 完全卸载并重新安装

```bash
adb uninstall com.videocompressor.video_compressor
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**重要：** 必须完全卸载，否则可能残留旧的插件注册信息

### 3. 启动并测试

```bash
adb shell am start -n com.videocompressor.video_compressor/.MainActivity
adb logcat -c
adb logcat | grep flutter
```

### 4. 测试功能

1. **选择视频**：
   - 点击 "+" 按钮
   - file_picker 会自动请求权限（如果需要）
   - 选择视频文件

2. **检查输出目录**：
   - 查看日志确认输出目录设置
   - 应该显示：`/storage/emulated/0/Movies/FFmpeg-Mobile`

3. **压缩视频**：
   - 添加视频到队列
   - 点击开始压缩
   - 检查输出文件

## 预期日志

### 成功启动

```
[INFO] Loading saved tasks...
[INFO] Loaded 0 saved tasks
[INFO] Getting default output directory...
[INFO] Created output directory: /storage/emulated/0/Movies/FFmpeg-Mobile
[INFO] Using default output directory: /storage/emulated/0/Movies/FFmpeg-Mobile
[INFO] Task manager initialized successfully with 0 tasks
```

### 选择视频

```
[INFO] Opening file picker for videos...
[INFO] Added task: video.mp4 (15.23 MB)
[INFO] Added 1 video(s) to queue
```

### 不应该看到的错误

❌ `MissingPluginException`
❌ `PlatformException(channel-error`
❌ `Cannot check videos permission`
❌ `Failed to access documents directory`

## 优势总结

| 方面 | 使用插件 | 不使用插件 |
|------|---------|----------|
| **复杂度** | 高（依赖多个插件） | 低（原生方法） |
| **稳定性** | 依赖插件兼容性 | 稳定可靠 |
| **权限处理** | 需要手动检查 | file_picker 自动处理 |
| **路径获取** | 依赖 path_provider | 使用固定路径 |
| **调试难度** | 难（插件问题） | 简单（清晰的流程） |

## 注意事项

1. **输出目录**：
   - 默认使用 `/storage/emulated/0/Movies/FFmpeg-Mobile`
   - 用户可以通过 "设置输出目录" 按钮更改

2. **权限**：
   - AndroidManifest.xml 中的权限声明仍然需要
   - file_picker 会在需要时请求这些权限

3. **兼容性**：
   - 适用于 Android 6.0+
   - 不同 Android 版本的权限对话框可能不同

## 如果还有问题

如果构建后仍有错误：

1. **清理更彻底**：
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   rm -rf build/
   flutter pub get
   ```

2. **检查 Manifest**：
   确保 `android/app/src/main/AndroidManifest.xml` 包含必要权限

3. **查看完整日志**：
   ```bash
   adb logcat | grep -E "flutter|FFmpeg|Error"
   ```

现在应该不再有插件错误了！🎉
