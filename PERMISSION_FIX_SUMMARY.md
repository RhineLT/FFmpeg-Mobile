# 权限问题修复说明

## 问题分析

从提供的截图来看，应用在请求存储权限时遇到了问题：
- "Error checking storage permissions"
- "Error requesting storage permissions"
- "Storage permission denied"

## 根本原因

对比 Git 提交 `40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70`（换 FFmpeg 之前），发现以下关键差异：

### 1. AndroidManifest.xml 缺少关键权限

**之前版本有：**
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

**当前版本缺失此权限**

### 2. main.dart 初始化流程改变

**之前版本：**
- 使用 `async main()` 同步初始化
- 直接 await 服务初始化
- 简单的启动流程

**当前版本：**
- 复杂的异步错误处理
- FutureBuilder 延迟初始化
- 可能导致权限检查时机问题

## 修复内容

### 1. 恢复 AndroidManifest.xml 权限

**文件：** `android/app/src/main/AndroidManifest.xml`

添加了缺失的权限：
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

完整权限列表：
- `READ_EXTERNAL_STORAGE` - 读取外部存储
- `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=32) - 写入外部存储（Android 12 及以下）
- `READ_MEDIA_VIDEO` - 读取媒体视频（Android 13+）
- `MANAGE_EXTERNAL_STORAGE` - 管理外部存储（Android 11+）

### 2. 更新 PermissionService

**文件：** `lib/services/permission_service.dart`

添加了对 `MANAGE_EXTERNAL_STORAGE` 权限的支持：

```dart
// 请求权限时
final Map<Permission, PermissionStatus> statuses = await [
  Permission.videos,
  Permission.storage,
  Permission.manageExternalStorage,  // 新增
].request();

// 检查权限时
final manageStorageStatus = await Permission.manageExternalStorage.status;
return videosStatus.isGranted || storageStatus.isGranted || manageStorageStatus.isGranted;
```

### 3. 简化 main.dart 初始化流程

**文件：** `lib/main.dart`

恢复为之前的同步初始化流程：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final logService = LogService();
  await logService.init();

  final storageService = StorageService();
  
  final taskManager = TaskManager(
    logService: logService,
    storageService: storageService,
  );
  await taskManager.init();

  runApp(MyApp(
    logService: logService,
    taskManager: taskManager,
  ));
}
```

这样可以确保：
- 服务在应用启动前完全初始化
- 权限检查在正确的时机进行
- 避免竞态条件

### 4. 更新 Android SDK 版本

**文件：** `android/app/build.gradle.kts`

```kotlin
compileSdk = 36  // 从 34 升级到 36
targetSdk = 36   // 从 34 升级到 36
```

这是为了满足新版本 FFmpeg Kit 和其他插件的要求。

## 权限请求流程

### Android 版本差异处理

应用现在正确处理不同 Android 版本的权限：

1. **Android 13+ (API 33+)**
   - 主要使用 `READ_MEDIA_VIDEO`
   - 细粒度媒体权限

2. **Android 11-12 (API 30-32)**
   - 使用 `MANAGE_EXTERNAL_STORAGE`
   - 或 `READ_EXTERNAL_STORAGE` + `WRITE_EXTERNAL_STORAGE`

3. **Android 10 及以下 (API 29-)**
   - 使用 `READ_EXTERNAL_STORAGE` + `WRITE_EXTERNAL_STORAGE`

### 请求时机

权限在以下时机请求：

1. **用户选择视频时** (TaskManager.pickVideos)
   ```dart
   // Check and request permissions first
   final hasPermission = await permissionService.hasStoragePermissions();
   if (!hasPermission) {
     final granted = await permissionService.requestStoragePermissions();
     if (!granted) {
       logService.error('Storage permission denied');
       return;
     }
   }
   ```

2. **用户选择输出目录时** (TaskManager.selectOutputDirectory)

## 测试步骤

### 1. 清理和重新构建

```bash
# 执行测试脚本
./test_permission_build.sh
```

或手动执行：

```bash
# 清理
flutter clean
cd android && ./gradlew clean && cd ..

# 获取依赖
flutter pub get

# 构建
flutter build apk --debug
```

### 2. 安装和测试

```bash
# 卸载旧版本
adb uninstall com.videocompressor.video_compressor

# 安装新版本
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 启动应用
adb shell am start -n com.videocompressor.video_compressor/.MainActivity

# 查看日志
adb logcat -s flutter
```

### 3. 验证权限

在应用中：

1. **点击 "+" 按钮** - 应该弹出权限请求对话框
2. **授予权限** - 应该能选择视频文件
3. **查看日志** - 应该显示 "Storage permissions granted"

### 4. 检查系统权限

```bash
# 检查应用权限
adb shell dumpsys package com.videocompressor.video_compressor | grep permission
```

应该看到：
- `android.permission.READ_EXTERNAL_STORAGE: granted=true`
- `android.permission.READ_MEDIA_VIDEO: granted=true`
- `android.permission.MANAGE_EXTERNAL_STORAGE: granted=true` (如果 Android 11+)

## 预期行为

修复后的应用应该：

1. ✅ 正常请求存储权限
2. ✅ 能够选择视频文件
3. ✅ 能够选择输出目录
4. ✅ 日志中不再出现权限错误
5. ✅ 能够正常访问和压缩视频

## 与之前版本的对比

| 特性 | 之前版本 (40d1ac5) | 当前版本（修复后） |
|------|-------------------|------------------|
| MANAGE_EXTERNAL_STORAGE | ✅ 有 | ✅ 有 |
| 初始化流程 | 同步 | 同步 |
| 权限检查 | 完整 | 完整 |
| Android SDK | 34 | 36 |
| FFmpeg | ❌ 无 | ✅ ffmpeg_kit_flutter_new |

## 注意事项

### MANAGE_EXTERNAL_STORAGE 权限

这是一个特殊权限，需要用户手动在系统设置中授予：

1. 应用首次请求时会跳转到设置页面
2. 用户需要手动打开 "允许管理所有文件" 开关
3. 这是 Android 11+ 访问外部存储的推荐方式

### 如果权限仍被拒绝

用户可以：

1. 打开系统设置
2. 找到应用权限设置
3. 手动授予所需权限

或在应用中点击 "打开设置" 按钮（如果实现了）。

## 后续优化建议

1. **添加权限说明界面**
   - 在请求权限前显示说明
   - 解释为什么需要这些权限

2. **改进权限拒绝处理**
   - 显示友好的错误提示
   - 提供 "打开设置" 按钮

3. **添加权限状态检查**
   - 在主界面显示权限状态
   - 提供一键请求所有权限的功能

## 总结

本次修复主要恢复了换用 FFmpeg 后丢失的关键权限配置和初始化流程，使应用的权限请求机制回到稳定的工作状态。修复内容包括：

1. ✅ 恢复 MANAGE_EXTERNAL_STORAGE 权限
2. ✅ 更新 PermissionService 支持所有权限类型
3. ✅ 简化 main.dart 初始化流程
4. ✅ 更新 Android SDK 版本以兼容新插件

所有更改都基于之前稳定版本的配置，确保权限请求功能正常工作。
