# 权限修复验证指南

## 快速验证

### 1. 代码验证

#### ✅ AndroidManifest.xml
```bash
grep "MANAGE_EXTERNAL_STORAGE" android/app/src/main/AndroidManifest.xml
```
**预期输出：**
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

#### ✅ PermissionService
```bash
grep "manageExternalStorage" lib/services/permission_service.dart
```
**预期输出：** 应该看到多处引用

#### ✅ main.dart
```bash
grep "async main" lib/main.dart
```
**预期输出：**
```dart
void main() async {
```

### 2. 构建验证

```bash
# 清理并构建
flutter clean
flutter pub get
flutter build apk --debug

# 检查构建产物
ls -lh build/app/outputs/flutter-apk/app-debug.apk
```

### 3. 权限验证（安装后）

```bash
# 安装应用
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 检查声明的权限
adb shell dumpsys package com.videocompressor.video_compressor | grep "permission"

# 启动应用
adb shell am start -n com.videocompressor.video_compressor/.MainActivity

# 实时查看日志
adb logcat -s flutter | grep -i "permission\|storage"
```

## 详细测试步骤

### 步骤 1: 首次启动
1. 启动应用
2. 观察是否有崩溃或初始化错误
3. 查看日志中的初始化信息

**预期日志：**
```
[INFO] Task manager initialized with 0 tasks
[INFO] Compression settings: -hwaccel auto -c:v libx265...
```

### 步骤 2: 请求权限
1. 点击主界面的 "+" 按钮
2. 观察权限请求对话框

**预期行为：**
- Android 13+: 显示 "允许访问照片和视频" 对话框
- Android 11-12: 显示 "允许管理所有文件" 对话框
- Android 10-: 显示 "允许访问存储" 对话框

**预期日志：**
```
[INFO] Requesting storage permissions
[INFO] Storage permissions granted
```

### 步骤 3: 选择视频
1. 授予权限后
2. 文件选择器应该打开
3. 能够浏览并选择视频文件

**预期日志：**
```
[INFO] Added task: video.mp4 (15.23 MB)
[INFO] Added 1 video(s) to queue
```

### 步骤 4: 设置输出目录
1. 点击工具栏的文件夹图标
2. 能够选择任意目录

**预期日志：**
```
[INFO] Output directory set to: /storage/emulated/0/...
```

### 步骤 5: 压缩视频
1. 点击播放按钮开始压缩
2. 观察进度显示
3. 等待完成

**预期日志：**
```
[INFO] Started processing queue
[INFO] Starting compression for: video.mp4
[INFO] Compression completed: video.mp4
```

## 常见问题排查

### ❌ 问题: 仍然提示 "Storage permission denied"

**解决方案:**
1. 卸载应用: `adb uninstall com.videocompressor.video_compressor`
2. 重新安装: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
3. 手动授予权限:
   - 设置 → 应用 → FFmpeg-Mobile → 权限
   - 打开所有存储权限

### ❌ 问题: 权限对话框不显示

**检查:**
```bash
# 确认权限已在 Manifest 中声明
grep "uses-permission" android/app/src/main/AndroidManifest.xml

# 确认权限请求代码正确
grep -A 10 "requestStoragePermissions" lib/services/permission_service.dart
```

### ❌ 问题: 应用启动崩溃

**检查日志:**
```bash
adb logcat | grep -E "FATAL|AndroidRuntime|flutter"
```

**常见原因:**
- 初始化顺序错误 → 检查 main.dart
- 权限冲突 → 检查 AndroidManifest.xml
- 服务未初始化 → 确保 async/await 正确

## 对比检查

### 与之前稳定版本对比

```bash
# 检查关键文件差异
git diff 40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70 HEAD -- android/app/src/main/AndroidManifest.xml
git diff 40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70 HEAD -- lib/services/permission_service.dart
git diff 40d1ac53ee9bdb2ffdd1aa05b7fb6c8b575efa70 HEAD -- lib/main.dart
```

**应该看到:**
- AndroidManifest.xml: MANAGE_EXTERNAL_STORAGE 已恢复
- permission_service.dart: manageExternalStorage 已添加
- main.dart: async main() 已恢复

## 成功标志

修复成功的标志：

- [x] 应用正常启动，无崩溃
- [x] 点击 "+" 按钮显示权限对话框
- [x] 授予权限后能选择视频文件
- [x] 能设置输出目录
- [x] 日志显示 "Storage permissions granted"
- [x] 能成功压缩视频
- [x] 无权限相关错误日志

## 性能验证

### 日志关键点

**启动阶段:**
```
✓ LogService initialized
✓ TaskManager initialized with N tasks
✓ Compression settings loaded
```

**权限阶段:**
```
✓ Requesting storage permissions
✓ Storage permissions granted
```

**功能阶段:**
```
✓ Added video(s) to queue
✓ Output directory set
✓ Started processing queue
✓ Compression completed
```

### 时间指标

- 应用启动: < 2 秒
- 权限请求: 即时显示对话框
- 文件选择: < 1 秒打开选择器
- 压缩启动: < 1 秒开始处理

## 最终确认

完成所有测试后，确认：

1. ✅ 所有权限正常请求和授予
2. ✅ 文件选择功能正常
3. ✅ 视频压缩功能正常
4. ✅ 无权限相关错误
5. ✅ 用户体验流畅

如果以上都通过，则权限修复成功！🎉
