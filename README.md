# FFmpeg Mobile - 视频压缩应用

一个强大的 Flutter 视频压缩应用，支持 iOS 和 Android 平台。

## ⚠️ 重要更新

**原 FFmpeg Kit 库已被官方废弃**（2025年4月1日）。本项目已迁移到使用 `video_compress` 库，该库：
- ✅ 活跃维护中
- ✅ Android 使用 MediaCodec
- ✅ iOS 使用 AVAssetExportSession  
- ✅ 提供良好的压缩质量和性能

## 功能特性

### 核心功能
- 📹 **批量视频压缩** - 支持选择多个视频文件进行压缩
- 🎯 **高质量压缩** - 使用平台原生编码器实现高质量压缩
- 📊 **实时进度跟踪** - 显示每个视频的压缩进度
- 💾 **自动保存状态** - 支持中途退出后恢复
- 📝 **完善的日志系统** - 记录所有操作和错误信息
- 🔄 **任务队列管理** - 自动按顺序处理压缩任务

### 技术特性
- **Provider 状态管理** - 响应式 UI 更新
- **本地数据持久化** - SharedPreferences 存储任务状态
- **权限管理** - 自动请求必要的存储权限
- **错误处理** - 完善的异常处理和恢复机制

## 快速开始

### 环境要求

- Flutter SDK: ^3.35.7
- Dart SDK: ^3.9.2
- Android SDK: API 21+ (Android 5.0+)
- iOS: 10.0+

### 构建指南

#### Android 构建

```bash
# 安装依赖
flutter pub get

# 分析代码
flutter analyze

# 构建 Debug APK (使用 --no-daemon 避免内存问题)
cd android
./gradlew assembleDebug --no-daemon
cd ..

# 或使用 Flutter 命令
flutter build apk --debug

# 构建 Release APK
flutter build apk --release
```

生成的 APK 位置：`build/app/outputs/flutter-apk/`

#### iOS 构建

```bash
# 安装依赖
flutter pub get

# 构建 iOS
flutter build ios --release
```

## 项目结构
