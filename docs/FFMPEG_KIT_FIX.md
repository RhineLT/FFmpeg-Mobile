# FFmpeg-Kit 依赖解决方案

## 问题总结
所有 `ffmpeg_kit_flutter` 包（6.0.3版本）都依赖 `com.arthenica:ffmpeg-kit-*:6.0-2`，该版本在标准 Maven 仓库中不可用。

## 临时解决方案

### 方案 A: 使用 5.1 版本的 ffmpeg_kit_flutter

```yaml
dependencies:
  ffmpeg_kit_flutter_video: ^5.1.0
```

5.1 版本依赖 `ffmpeg-kit-video:5.1`，该版本在 Maven Central 可用。

### 方案 B: 手动集成 FFmpeg-Kit AAR

1. 从 GitHub Releases 下载预编译的 AAR:
```bash
wget https://github.com/arthenica/ffmpeg-kit/releases/download/v6.0/ffmpeg-kit-video-6.0-2.aar
```

2. 将 AAR 复制到项目:
```bash
mkdir -p android/app/libs
cp ffmpeg-kit-video-6.0-2.aar android/app/libs/
```

3. 修改 `android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))
    // ... 其他依赖
}
```

4. 修改插件依赖 (需要修补 pub cache 中的文件):
```bash
# 修改 ~/.pub-cache/hosted/pub.dev/ffmpeg_kit_flutter_video-6.0.3/android/build.gradle
# 注释掉或删除远程依赖行
```

### 方案 C: Fork ffmpeg_kit_flutter 并修复

1. Fork https://github.com/arthenica/ffmpeg-kit-flutter
2. 更新 `android/build.gradle` 中的版本号
3. 发布到自己的仓库
4. 在 `pubspec.yaml` 中使用 git 依赖

### 方案 D: 回退到稳定方案

使用经过验证的视频压缩库：
- `video_compress` - 简单但功能有限
- `light_compressor` - 较新的选择
- 或者保持当前代码，在 CI 环境问题解决后再测试

## 推荐行动

**短期 (立即)**: 使用方案 A，降级到 5.1 版本
**中期**: 监控 ffmpeg_kit_flutter 的更新
**长期**: 考虑自己维护一个 FFmpeg wrapper

## 实施步骤 (方案 A)

```bash
# 1. 更新 pubspec.yaml
sed -i 's/ffmpeg_kit_flutter_video: ^6.0.3/ffmpeg_kit_flutter_video: ^5.1.0/' pubspec.yaml

# 2. 清理并获取依赖
flutter clean
flutter pub get

# 3. 测试构建
flutter build apk --release

# 4. 提交
git add pubspec.yaml
git commit -m "fix: downgrade to ffmpeg_kit_flutter_video 5.1 for Maven compatibility"
git push
```
