# 性能优化技术方案

## 当前限制

### video_compress 库的局限性
当前使用的 `video_compress: ^3.1.4` 库：
- ✅ 优点：简单、稳定、跨平台
- ❌ 限制：不支持自定义 FFmpeg 参数
- ❌ 限制：使用平台默认编码器设置
- ❌ 限制：无法精确控制 CRF、preset 等参数

### 平台原生编码器

#### Android (MediaCodec)
```kotlin
// 当前实现（video_compress 内部）
val encoder = MediaCodec.createEncoderByType("video/hevc")
// 或
val encoder = MediaCodec.createEncoderByType("video/avc")

// 参数控制有限
format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
format.setInteger(MediaFormat.KEY_FRAME_RATE, framerate)
format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, iFrameInterval)
```

#### iOS (AVAssetExportSession)
```swift
// 当前实现（video_compress 内部）
let exportSession = AVAssetExportSession(
    asset: asset,
    presetName: AVAssetExportPresetMediumQuality
)
```

## 解决方案

### 方案 1: 迁移到 FFmpeg 库 (推荐)

#### 1.1 使用社区维护的 FFmpeg Kit Fork

**候选库:**
```yaml
# Option 1: 社区 fork
dependencies:
  # 查找最新的 FFmpeg Kit 社区维护版本
  # 例如: ffmpeg_kit_flutter_full: ^版本号
```

**优点:**
- ✅ 完整的 FFmpeg 功能
- ✅ 支持所有参数
- ✅ 精确控制质量和速度

**缺点:**
- ❌ 需要重写压缩服务
- ❌ APK/IPA 体积增大（约 30-50MB）
- ❌ 可能的维护风险

**实施步骤:**
1. 研究可用的 FFmpeg Kit fork
2. 测试兼容性和性能
3. 重写 `VideoCompressionService`
4. 迁移现有任务
5. 全面测试

#### 1.2 使用其他 FFmpeg Flutter 插件

**候选:**
- `flutter_ffmpeg` 的 fork
- `ffmpeg_cli` + 自定义实现
- 直接使用 Method Channel 调用原生 FFmpeg

### 方案 2: 优化现有实现

#### 2.1 扩展 video_compress 库

**Fork 并修改源码:**
```dart
// 在 video_compress 插件中添加参数支持
class VideoQualityOptions {
  final int? crf;  
  final String? preset;
  final int? maxBitrate;
  // ...
}

Future<MediaInfo?> compressVideo(
  String path, {
  VideoQuality quality,
  VideoQualityOptions? advancedOptions,  // 新增
  // ...
}) {
  // 传递参数到原生代码
}
```

**原生代码修改 (Android):**
```kotlin
// VideoCompressPlugin.kt
private fun configureEncoder(
    format: MediaFormat,
    options: Map<String, Any>?
) {
    options?.let {
        // CRF equivalent for MediaCodec
        val crf = it["crf"] as? Int
        if (crf != null) {
            // 转换 CRF 到 bitrate
            val bitrate = calculateBitrateFromCRF(crf, width, height)
            format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        }
        
        // Quality preset
        val preset = it["preset"] as? String
        preset?.let { p ->
            configurePreset(format, p)
        }
    }
}
```

**优点:**
- ✅ 保持现有架构
- ✅ APK 体积不变
- ✅ 渐进式改进

**缺点:**
- ❌ 需要维护自己的 fork
- ❌ MediaCodec 不支持真正的 CRF
- ❌ 参数控制受限

#### 2.2 使用平台最佳实践

**Android MediaCodec 优化:**
```kotlin
// 质量优先配置
format.setInteger(
    MediaFormat.KEY_BITRATE_MODE,
    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR
)

// 编码复杂度
format.setInteger(
    MediaFormat.KEY_COMPLEXITY,
    when (preset) {
        "fast" -> MediaCodecInfo.EncoderCapabilities.COMPLEXITY_FAST
        "medium" -> MediaCodecInfo.EncoderCapabilities.COMPLEXITY_BALANCED
        "slow" -> MediaCodecInfo.EncoderCapabilities.COMPLEXITY_HIGHEST
        else -> MediaCodecInfo.EncoderCapabilities.COMPLEXITY_BALANCED
    }
)

// H.265 特定设置
if (codec == "hevc") {
    format.setString(
        MediaFormat.KEY_PROFILE,
        MediaCodecInfo.CodecProfileLevel.HEVCProfileMain
    )
}
```

**iOS AVFoundation 优化:**
```swift
// 使用 AVAssetWriter 替代 AVAssetExportSession
let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: bitrate,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoQualityKey: quality  // 0.0 - 1.0
    ]
]
```

### 方案 3: 混合方案

**结合平台特性:**
```dart
class SmartCompressionService {
  Future<void> compress(VideoTask task) async {
    if (Platform.isAndroid) {
      // Android: 使用 MediaCodec 优化
      return _compressWithMediaCodec(task);
    } else if (Platform.isIOS) {
      // iOS: 使用 AVAssetWriter
      return _compressWithAVAssetWriter(task);
    }
  }
}
```

## 性能优化策略

### 1. 硬件加速

#### Android
```kotlin
// 优先使用硬件编码器
fun findBestEncoder(mimeType: String): MediaCodec {
    val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
    val codecs = codecList.codecInfos
        .filter { it.isEncoder }
        .filter { it.supportedTypes.contains(mimeType) }
        .filter { !it.name.contains("OMX.google") }  // 避免软件编码器
        .sortedByDescending { it.capabilities.isHardwareAccelerated }
    
    return MediaCodec.createByCodecName(codecs.first().name)
}
```

#### iOS
```swift
// VideoToolbox 硬件编码
let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc,
    AVVideoEncoderSpecificationKey: [
        kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: true
    ]
]
```

### 2. 多线程优化

```dart
class ConcurrentCompressionService {
  final int maxConcurrentTasks = Platform.isIOS ? 1 : 2;  // iOS 限制更严
  
  Future<void> processQueue() async {
    final tasks = pendingTasks.take(maxConcurrentTasks);
    await Future.wait(
      tasks.map((task) => compress(task)),
      eagerError: false,
    );
  }
}
```

### 3. 内存管理

```dart
class MemoryAwareCompression {
  static const int maxMemoryMB = 512;
  
  Future<bool> canStartNewTask() async {
    final memory = await getAvailableMemory();
    return memory > maxMemoryMB * 1024 * 1024;
  }
  
  Future<void> compress(VideoTask task) async {
    // 大文件分段处理
    if (task.fileSize > 500 * 1024 * 1024) {
      return _compressInChunks(task);
    }
    return _compressWhole(task);
  }
}
```

### 4. 后台处理

#### Android Foreground Service
```kotlin
class CompressionService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // 压缩任务
        startCompression()
        
        return START_STICKY
    }
}
```

#### iOS Background Tasks
```swift
import BackgroundTasks

// 注册后台任务
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.ffmpegmobile.compression",
    using: nil
) { task in
    self.handleCompression(task: task as! BGProcessingTask)
}

// 请求后台时间
func scheduleCompression() {
    let request = BGProcessingTaskRequest(
        identifier: "com.ffmpegmobile.compression"
    )
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false
    
    try? BGTaskScheduler.shared.submit(request)
}
```

## 推荐实施路径

### 短期 (1-2 周)
1. ✅ 完成 UI 和参数管理（已完成）
2. 🔄 优化 video_compress 使用方式
3. 🔄 实现内存管理和错误恢复

### 中期 (1 个月)
1. 🔜 研究并测试 FFmpeg Kit 社区 fork
2. 🔜 实现后台处理服务
3. 🔜 添加批量压缩优化

### 长期 (2-3 个月)
1. 🔜 迁移到真正的 FFmpeg 实现
2. 🔜 实现多任务并发
3. 🔜 完整的性能分析和优化

## 性能基准

### 目标指标
- **编码速度**: ≥0.5x (实时的一半)
- **内存使用**: ≤512MB
- **电池消耗**: 中等
- **崩溃率**: <0.1%
- **后台存活**: ≥10分钟

### 测试方案
```dart
class PerformanceMonitor {
  DateTime? startTime;
  int processedFrames = 0;
  
  void startMonitoring() {
    startTime = DateTime.now();
  }
  
  void endMonitoring(VideoTask task) {
    final duration = DateTime.now().difference(startTime!);
    final speed = task.duration / duration.inSeconds;
    
    logService.info(
      'Performance: ${speed}x speed, '
      '${processedFrames / duration.inSeconds} fps'
    );
  }
}
```

## 总结

当前应用已具备完整的参数管理界面，为性能优化奠定了基础。下一步应：

1. **评估 FFmpeg Kit fork** - 确定是否可以安全使用
2. **优化现有实现** - 充分利用平台能力
3. **渐进式改进** - 不破坏现有功能

无论选择哪个方案，用户界面和参数管理系统已经准备就绪，可以无缝对接新的压缩引擎。
