# 权限配置恢复说明

## 修复策略调整

经过分析之前可以正常工作的版本（commit `40d1ac53`），我已经将权限处理恢复到**更简单、更有效**的方式。

## 关键变化

### ❌ 之前的复杂方案（已废弃）
- 应用启动时就请求权限
- 根据 Android 版本复杂判断
- 使用 device_info_plus 检测 SDK 版本
- 显示专门的权限请求界面

### ✅ 当前的简单方案（恢复工作）
- **懒加载权限**：仅在用户点击"添加视频"时才请求权限
- **系统自动处理**：同时请求 `Permission.videos` 和 `Permission.storage`，让 Android 系统根据版本自动选择
- **无需版本检测**：permission_handler 插件会自动处理版本差异

## 修改的文件

### 1. AndroidManifest.xml
恢复到简单配置：
```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

**说明**：
- `READ_EXTERNAL_STORAGE`: Android 12 及以下使用
- `READ_MEDIA_VIDEO`: Android 13+ 使用
- 系统会根据 Android 版本自动使用正确的权限

### 2. PermissionService.dart
恢复到简单实现：
```dart
Future<bool> requestStoragePermissions() async {
  // 同时请求两个权限，让系统选择
  final Map<Permission, PermissionStatus> statuses = await [
    Permission.videos,
    Permission.storage,
  ].request();
  
  // 只要有一个授权就可以
  return statuses[Permission.videos]?.isGranted ?? false ||
         statuses[Permission.storage]?.isGranted ?? false;
}
```

**关键点**：
- 不需要检测 Android 版本
- permission_handler 插件会自动处理版本差异
- 更简洁、更可靠

### 3. main.dart
恢复到简单启动流程：
```dart
void main() {
  // 直接启动，不检查权限
  runApp(MyApp(...));
}
```

**说明**：
- 应用启动时不再检查或请求权限
- 权限在需要时（用户操作时）才请求

### 4. TaskManager.pickVideos()
在用户操作时请求权限：
```dart
Future<void> pickVideos() async {
  // 检查权限
  final hasPermission = await permissionService.hasStoragePermissions();
  if (!hasPermission) {
    // 请求权限
    final granted = await permissionService.requestStoragePermissions();
    if (!granted) {
      logService.error('Storage permission denied');
      return;
    }
  }
  
  // 选择视频
  final result = await FilePicker.platform.pickFiles(...);
}
```

## 权限请求流程

```
用户启动应用
  ↓
显示主界面（无需权限）
  ↓
用户点击"添加视频"按钮
  ↓
检查是否已有权限
  ├─ 有 → 直接打开文件选择器
  └─ 无 → 弹出系统权限对话框
         ↓
       用户授权
         ↓
       打开文件选择器
```

## 优势

1. **用户体验更好**
   - 应用快速启动，无需等待权限检查
   - 在需要时才请求权限（更符合用户预期）

2. **代码更简单**
   - 无需版本检测逻辑
   - 无需专门的权限界面
   - 依赖系统自动处理

3. **更可靠**
   - 与之前可以工作的版本一致
   - permission_handler 插件已经处理了版本兼容性
   - 减少了出错的可能性

4. **符合最佳实践**
   - Android 推荐在使用时请求权限（runtime permissions）
   - 懒加载策略减少用户困扰

## 删除的文件

- `/lib/screens/permission_screen.dart` - 不再需要专门的权限界面

## 不再需要的依赖

虽然 `device_info_plus` 已添加到 pubspec.yaml，但现在不再使用。可以保留（不影响）或移除。

## 测试方法

```bash
# 1. 卸载旧版本
adb uninstall com.videocompressor.video_compressor

# 2. 运行应用
flutter run

# 3. 测试步骤
# - 应用直接启动到主界面 ✓
# - 点击"添加视频"按钮
# - 系统弹出权限请求对话框 ✓
# - 授权后能选择视频 ✓
```

## 预期行为

### 首次使用
1. 应用启动 → 直接显示主界面
2. 点击"添加视频" → 弹出权限对话框
3. 用户授权 → 打开文件选择器
4. 选择视频 → 添加到任务列表

### 已授权
1. 应用启动 → 直接显示主界面
2. 点击"添加视频" → 直接打开文件选择器（无权限对话框）
3. 选择视频 → 添加到任务列表

### 拒绝权限
1. 用户拒绝权限 → 日志记录"Storage permission denied"
2. 不会添加视频
3. 下次点击"添加视频"时会再次请求

## 为什么这种方式更好

这是参考之前可以正常工作的版本（commit `40d1ac53`）恢复的配置。之前的复杂方案虽然看起来很完善，但实际上：

1. **过度工程化** - 不需要那么复杂的版本检测
2. **启动慢** - 在启动时检查权限会延迟应用启动
3. **用户困惑** - 应用刚启动就要求权限可能让用户困惑
4. **插件已处理** - permission_handler 插件已经处理了所有版本兼容性

**简单就是美！** 这个方案已经在之前的版本中证明是可行的。

---

**恢复时间**: 2025-10-29  
**基于版本**: commit `40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70`  
**状态**: ✅ 完成，等待测试
