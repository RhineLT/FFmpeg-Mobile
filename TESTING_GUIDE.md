# Android 应用测试指南

## 修复内容总结

已修复 Android 应用启动时的 `SharedPreferences` 初始化失败问题：

✅ **修复前的错误**:
```
应用初始化失败
错误: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.shared_preferences_android.SharedPreferencesApi.getAll"., null, null)
```

✅ **已实施的修复**:
1. 重构 `StorageService` 和 `LogService` 的初始化流程
2. 添加 SharedPreferences 单例模式，避免重复初始化
3. 优化服务初始化顺序
4. 增强错误处理和日志输出
5. 改进错误显示界面

## 测试步骤

### 1. 下载最新的 APK

从 GitHub Actions 下载最新构建的 APK：
```bash
gh run download 18902886433 -n android-release-apk
```

或者直接访问：
https://github.com/RhineLT/FFmpeg-Mobile/actions/runs/18902886433

### 2. 安装到 Android 设备

```bash
# 卸载旧版本（如果有）
adb uninstall com.videocompressor.video_compressor

# 安装新版本
adb install -r app-release.apk
```

### 3. 启动应用并观察

**预期结果**：
- ✅ 应用正常启动，显示主界面
- ✅ 没有红色错误图标
- ✅ 可以看到任务列表（即使是空的）

**如果仍然失败**：
- ❌ 会显示详细的错误界面
- ❌ 包含完整的错误消息和堆栈跟踪

### 4. 查看日志（推荐）

即使应用正常启动，也建议查看日志确认初始化过程：

```bash
# 清除旧日志
adb logcat -c

# 启动应用后实时查看日志
adb logcat -s FFmpeg-Mobile:* flutter:* StorageService:* LogService:* *:E
```

**预期的日志输出**：
```
FFmpeg-Mobile: App starting...
FFmpeg-Mobile: Initializing LogService...
LogService: Initializing SharedPreferences...
LogService: SharedPreferences initialized
LogService: Loaded 0 log entries
FFmpeg-Mobile: LogService initialized
FFmpeg-Mobile: Initializing StorageService...
StorageService: Initializing SharedPreferences...
StorageService: SharedPreferences initialized successfully
FFmpeg-Mobile: StorageService initialized
FFmpeg-Mobile: Creating TaskManager...
FFmpeg-Mobile: Initializing TaskManager...
StorageService: No saved tasks found
StorageService: No saved compression settings found, using defaults
FFmpeg-Mobile: TaskManager initialized
FFmpeg-Mobile: Running app...
```

### 5. 功能测试

如果应用正常启动，测试以下功能：

#### 5.1 添加视频任务
- [ ] 点击"添加视频"按钮
- [ ] 选择一个视频文件
- [ ] 任务应该出现在列表中

#### 5.2 设置压缩参数
- [ ] 打开设置界面
- [ ] 修改分辨率、比特率等参数
- [ ] 保存设置
- [ ] 重启应用，检查设置是否保留

#### 5.3 执行压缩任务
- [ ] 选择一个任务
- [ ] 点击开始压缩
- [ ] 观察进度条更新
- [ ] 等待压缩完成

#### 5.4 查看日志
- [ ] 打开日志界面
- [ ] 应该能看到操作日志
- [ ] 重启应用后日志应该保留

#### 5.5 数据持久化
- [ ] 添加几个任务
- [ ] 完全关闭应用（从最近任务中清除）
- [ ] 重新启动应用
- [ ] 任务列表应该保留

### 6. 压力测试

如果基本功能正常，进行压力测试：

#### 6.1 快速重启
```bash
# 重复启动和停止应用
for i in {1..10}; do
  adb shell am start -n com.videocompressor.video_compressor/.MainActivity
  sleep 2
  adb shell am force-stop com.videocompressor.video_compressor
  sleep 1
done
```

#### 6.2 低内存环境
- 打开多个大型应用（Chrome、相机等）
- 启动视频压缩应用
- 检查是否能正常初始化

#### 6.3 网络异常
- 开启飞行模式
- 启动应用（应该仍能正常工作，因为不依赖网络）

## 已知问题和限制

### 当前版本的改进
1. ✅ 修复了 SharedPreferences 初始化失败
2. ✅ 添加了详细的初始化日志
3. ✅ 改进了错误显示界面
4. ✅ 增强了服务的错误恢复能力

### 仍需注意的事项
1. ⚠️ FFmpeg Kit 库比较大（~50MB），首次安装可能需要时间
2. ⚠️ 视频压缩需要存储权限，首次使用会请求权限
3. ⚠️ 压缩大视频会占用较多内存

## 故障排除

### 问题 1: 应用仍然显示初始化错误

**解决步骤**：
1. 查看错误界面上的完整错误消息
2. 使用 `adb logcat` 查看详细日志
3. 截图错误界面并提供给开发团队
4. 提供设备信息：
   ```bash
   adb shell getprop ro.build.version.release  # Android 版本
   adb shell getprop ro.product.model          # 设备型号
   ```

### 问题 2: 应用闪退

**解决步骤**：
```bash
# 捕获崩溃日志
adb logcat -b crash > crash.log

# 或者查看完整日志
adb logcat > full.log
```

### 问题 3: SharedPreferences 无法保存数据

**检查存储权限**：
```bash
adb shell dumpsys package com.videocompressor.video_compressor | grep permission
```

## 成功标准

应用修复成功的标准：
- ✅ 应用能正常启动并显示主界面
- ✅ logcat 中能看到完整的初始化日志序列
- ✅ 没有 PlatformException 错误
- ✅ 任务和设置能正常保存和加载
- ✅ 多次重启应用数据不丢失
- ✅ CI/CD 构建通过

## 联系方式

如果遇到问题，请提供以下信息：
1. 错误截图
2. `adb logcat` 日志（至少包含应用启动过程）
3. 设备型号和 Android 版本
4. 复现步骤

---

**当前构建信息**：
- Commit: 30e5f19
- CI/CD Run: #18902886433
- 构建时间: 2025-10-29
- 状态: ✅ 成功
