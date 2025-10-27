# 快速开始指南

## 环境配置

由于您是新环境，需要按照以下步骤配置开发环境。

### 1. 当前项目状态

✅ Flutter 项目已创建
✅ 所有依赖已配置
# 快速开始指南

## 环境配置概览

该项目已针对 Flutter 3.35.7 / Dart 3.9.2 配置完成。您需要确保本地具备以下条件：

- Flutter SDK 已安装并可执行 (`flutter doctor` 正常)
- Android SDK / Xcode 根据目标平台部署
- Git、Java、CMake 等工具由 `flutter doctor` 检测通过

## 常用场景

### A. 在 Android 模拟器上调试

1. 安装 Android Studio 或命令行工具
2. 使用 AVD Manager 创建模拟器（或 `flutter emulators --create`）
3. 启动模拟器并运行项目：
   ```bash
   cd /workspaces/FFmpeg-Mobile
   flutter emulators --launch <emulator_id>
   flutter run
   ```

### B. 真机联调（推荐）

**Android**

```bash
cd /workspaces/FFmpeg-Mobile
flutter devices         # 确认设备已连接
flutter run             # 自动安装并运行
```

**iOS**

1. 在 macOS + Xcode 环境下配置开发者证书
2. 连接设备后执行：
   ```bash
   cd /workspaces/FFmpeg-Mobile
   flutter run
   ```

### C. 构建可安装包

```bash
cd /workspaces/FFmpeg-Mobile
flutter build apk --debug     # 调试包
flutter build apk --release   # 发布包
# 产物: build/app/outputs/flutter-apk/
```

后续会通过 GitHub Actions 扩展 iOS `.ipa`、Android `.aab` 构建流程。

## 深度配置提示（可选）

```bash
# 安装 Android 命令行工具（示例）
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip -d $HOME/android-sdk

export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
flutter doctor --android-licenses
flutter doctor
```

## 项目结构速览

```
/workspaces/FFmpeg-Mobile/
├── android/                # 原生 Android 工程
├── ios/                    # 原生 iOS 工程
├── lib/                    # Flutter 源码
├── test/                   # 测试
├── docs/                   # 文档
├── pubspec.yaml            # 依赖配置
└── quick_start.sh          # 辅助脚本
```

## 常用命令

```bash
cd /workspaces/FFmpeg-Mobile

flutter pub get             # 安装依赖
flutter analyze             # 静态分析
flutter test                # 单元 / 小部件测试
flutter run                 # 调试运行
flutter build apk           # 构建 APK
flutter clean               # 清理由生成物
flutter doctor              # 查看环境状态
```

## 功能测试清单

- [ ] 选择输出目录
- [ ] 批量添加视频任务
- [ ] H.265 压缩执行
- [ ] 暂停 / 恢复任务
- [ ] 查看实时进度与统计
- [ ] 检查日志记录
- [ ] 重试失败任务
- [ ] 删除任务 / 清理已完成
- [ ] 应用重启后恢复状态
- [ ] 校验输出文件是否写入目标目录

## 故障排查

- **FFmpeg Kit discontinued 提示**：仍可正常使用，如需替换可评估 `flutter_ffmpeg` 或平台通道方案。
- **权限问题**：Android 需授予存储权限；iOS 权限提示已在 `Info.plist` 配置，若被拒绝需到系统设置重新授权。
- **调试日志**：执行 `flutter run --verbose` 或在 VS Code 内启用调试视图。

## 后续步骤

1. 运行 `flutter analyze` / `flutter test`，确保基线健康
2. 连接 Android 设备完成首轮压缩验证
3. 梳理异常处理与日志持久化细节
4. 通过 GitHub Actions 搭建安卓 & iOS 构建流水线

如遇困难，可阅读 `docs/PROJECT_OVERVIEW.md` 与 `docs/DEVELOPMENT_SUMMARY.md`，了解架构与迭代计划。

