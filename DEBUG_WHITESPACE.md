# 白屏问题诊断指南

## 问题描述
Android 应用启动后出现白屏,无法正常显示界面。

## 已实施的诊断措施

### 1. 错误捕获和日志
- ✅ 添加 `runZonedGuarded` 捕获所有未处理异常
- ✅ 添加详细的初始化日志
- ✅ 错误时显示友好的错误界面
- ✅ 使用 `dart:developer.log` 输出到 logcat

### 2. Android 配置
- ✅ 添加 Proguard 规则防止 FFmpeg Kit 类被混淆
- ✅ 配置 release 构建使用 Proguard
- ✅ 保持所有 FFmpeg Kit 和 native 方法

### 3. FFmpeg Kit 测试
- ✅ 创建最小化测试版本 (`lib/main_test_ffmpeg.dart`)
- ✅ 测试 FFmpeg Kit 基本功能加载

## 诊断步骤

### 步骤 1: 查看 logcat 日志

连接 Android 设备后运行:

```bash
# 实时查看应用日志
adb logcat -s FFmpeg-Mobile:* flutter:* *:E

# 或过滤特定标签
adb logcat | grep -E "FFmpeg|Flutter|ERROR"

# 清除旧日志后重新运行
adb logcat -c
flutter run
adb logcat -s FFmpeg-Mobile:*
```

### 步骤 2: 测试 FFmpeg Kit 加载

使用测试版本验证 FFmpeg Kit 是否能正常加载:

```bash
# 切换到测试模式
./switch_main.sh test

# 运行应用
flutter run

# 查看日志
adb logcat -s FFmpeg-Test:*

# 恢复原始版本
./switch_main.sh restore
```

### 步骤 3: 检查权限

确保在设备上授予了所有必需的权限:
- 存储权限 (READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE)
- 媒体权限 (READ_MEDIA_VIDEO)

### 步骤 4: 检查 APK 大小

```bash
# 构建 APK
flutter build apk --debug

# 检查 APK 大小和内容
ls -lh build/app/outputs/flutter-apk/app-debug.apk
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep -i ffmpeg
```

## 常见原因和解决方案

### 1. FFmpeg Kit 库未正确加载
**症状**: 白屏,无错误信息  
**解决**:
- 检查 `pubspec.yaml` 中依赖版本
- 运行 `flutter clean && flutter pub get`
- 检查 Android minSdk >= 24

### 2. 权限问题
**症状**: 应用启动后崩溃  
**解决**:
- 在 AndroidManifest.xml 中添加权限
- 运行时请求权限
- 检查 Android 13+ 的新权限模型

### 3. Proguard 混淆
**症状**: Release 构建崩溃,Debug 正常  
**解决**:
- 已添加 proguard-rules.pro
- 检查是否有其他被混淆的类

### 4. 初始化失败
**症状**: logcat 显示初始化错误  
**解决**:
- 检查 LogService 初始化
- 检查 StorageService 初始化
- 检查 TaskManager 初始化
- 检查文件系统访问权限

### 5. 内存不足
**症状**: 应用启动慢或崩溃  
**解决**:
- FFmpeg Kit Full-GPL 包较大 (~50MB)
- 检查设备可用内存
- 考虑使用 min-gpl 包减小体积

## 日志关键字

在 logcat 中查找这些关键字:

```bash
# 成功初始化
"App starting..."
"Initializing LogService..."
"Initializing StorageService..."
"Initializing TaskManager..."
"Running app..."

# FFmpeg Kit 加载
"FFmpeg Kit version:"
"FFmpeg version output:"

# 错误
"Fatal error during initialization:"
"Flutter Error:"
"Uncaught error:"
```

## 测试清单

- [ ] logcat 显示初始化日志
- [ ] FFmpeg Kit 测试版本能正常显示
- [ ] 权限已授予
- [ ] APK 包含 FFmpeg 库文件
- [ ] 设备有足够内存
- [ ] Android 版本 >= 7.0 (API 24)

## 收集诊断信息

如果问题仍未解决,请收集以下信息:

```bash
# 1. 完整 logcat
adb logcat > logcat_full.txt

# 2. 应用信息
adb shell dumpsys package com.videocompressor.video_compressor > package_info.txt

# 3. 系统信息
adb shell getprop > system_props.txt

# 4. 内存信息
adb shell dumpsys meminfo com.videocompressor.video_compressor > meminfo.txt

# 5. Flutter doctor
flutter doctor -v > flutter_doctor.txt
```

## 回滚方案

如果 FFmpeg Kit 无法正常工作,可以临时回滚到 video_compress:

```bash
git revert HEAD~5  # 回滚最近5个提交
flutter pub get
flutter run
```

---

**更新时间**: 2025-10-29  
**状态**: 等待设备测试和日志收集
