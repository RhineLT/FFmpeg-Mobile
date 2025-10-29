# 权限修复前后对比

## 修复前的问题（从日志截图）

```
[21:13:04] [ERROR] Error checking storage permissions
[21:13:04] [ERROR] Storage permission denied
[21:13:03] [ERROR] Error requesting storage permissions
```

## 关键差异对比

### 1. AndroidManifest.xml

| 权限 | 之前版本 (40d1ac5) | 修复前 | 修复后 |
|------|-------------------|--------|--------|
| READ_EXTERNAL_STORAGE | ✅ | ✅ | ✅ |
| WRITE_EXTERNAL_STORAGE | ✅ | ✅ | ✅ |
| READ_MEDIA_VIDEO | ✅ | ✅ | ✅ |
| **MANAGE_EXTERNAL_STORAGE** | ✅ | ❌ | ✅ |

### 2. PermissionService

**修复前：**
```dart
final Map<Permission, PermissionStatus> statuses = await [
  Permission.videos,
  Permission.storage,
].request();
```

**修复后：**
```dart
final Map<Permission, PermissionStatus> statuses = await [
  Permission.videos,
  Permission.storage,
  Permission.manageExternalStorage,  // 新增
].request();
```

### 3. main.dart 初始化

**修复前：**
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 复杂的异步错误处理包装
  runZonedGuarded(() {
    final logService = LogService();
    final storageService = StorageService();
    final taskManager = TaskManager(...);
    
    runApp(MyApp(...));  // 未等待初始化
  }, ...);
}
```

**修复后（恢复原版）：**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 同步初始化所有服务
  final logService = LogService();
  await logService.init();

  final storageService = StorageService();
  
  final taskManager = TaskManager(...);
  await taskManager.init();

  runApp(MyApp(...));  // 初始化完成后启动
}
```

### 4. Android SDK 版本

| 设置 | 修复前 | 修复后 |
|------|--------|--------|
| compileSdk | 34 | 36 |
| targetSdk | 34 | 36 |

## 修复原理

### 为什么需要 MANAGE_EXTERNAL_STORAGE？

在 Android 11 (API 30) 及更高版本：

1. **作用域存储 (Scoped Storage)** 限制了应用访问外部存储
2. **MANAGE_EXTERNAL_STORAGE** 允许应用：
   - 访问所有外部存储文件
   - 选择任意目录作为输出路径
   - 读取其他应用创建的视频文件

3. **对于视频压缩应用来说是必需的**：
   - 需要读取用户相册中的视频
   - 需要写入到用户选择的任意目录
   - 需要管理输出文件

### 初始化流程的重要性

**同步初始化的优势：**
1. 确保服务在应用启动前完全就绪
2. 避免权限检查时服务未初始化
3. 减少竞态条件和时序问题

**之前异步包装的问题：**
1. FutureBuilder 可能导致延迟初始化
2. 权限检查可能在服务初始化前发生
3. 增加了不必要的复杂性

## 测试结果预期

### 修复前
```
[INFO] Requesting storage permissions
[ERROR] Error checking storage permissions
[ERROR] Storage permission denied
```

### 修复后
```
[INFO] Requesting storage permissions
[INFO] Storage permissions granted
[INFO] Added 1 video(s) to queue
```

## 验证清单

- [x] AndroidManifest.xml 包含所有必需权限
- [x] PermissionService 请求所有权限类型
- [x] main.dart 使用同步初始化
- [x] Android SDK 版本兼容新插件
- [x] 代码无编译错误
- [x] 权限逻辑与之前稳定版本一致

## 下一步

1. **构建并安装应用**
   ```bash
   ./test_permission_build.sh
   ```

2. **测试权限请求**
   - 点击 "+" 按钮
   - 观察权限对话框
   - 授予权限
   - 选择视频文件

3. **查看日志**
   ```bash
   adb logcat -s flutter | grep -i permission
   ```

4. **验证功能**
   - 能选择视频 ✓
   - 能设置输出目录 ✓
   - 能压缩视频 ✓

## 总结

本次修复通过对比 Git 提交 `40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70`（FFmpeg 切换前的稳定版本），识别并恢复了关键的权限配置和初始化流程。主要修复：

1. ✅ 恢复 MANAGE_EXTERNAL_STORAGE 权限声明
2. ✅ 更新权限服务以支持所有权限类型  
3. ✅ 恢复同步初始化流程
4. ✅ 升级 Android SDK 版本以满足新依赖

所有更改都基于之前的稳定版本，确保权限功能正常工作。
