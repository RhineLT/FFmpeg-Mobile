# 迁移到 FFmpeg Kit New

## 变更说明

本项目已从 `video_compress` 迁移到 `ffmpeg_kit_flutter_new` (Full-GPL 版本)。

### 迁移原因

1. **功能限制**: `video_compress` 不支持自定义分辨率、CRF、preset 等参数
2. **真实 FFmpeg**: `ffmpeg_kit_flutter_new` 提供完整的 FFmpeg 功能
3. **持续维护**: 新库活跃维护,支持最新的 Flutter 和 Android 版本

### 技术栈

- **库**: `ffmpeg_kit_flutter_new ^4.1.0`
- **包类型**: Full-GPL (包含所有编解码器)
- **FFmpeg 版本**: v8.0.0
- **支持平台**: Android, iOS, macOS

### 新增功能

✅ **真正的 H.265/HEVC 编码**
- CRF 质量控制 (18-36)
- Preset 速度控制 (ultrafast - veryslow)
- 硬件加速支持

✅ **完整的参数控制**
- 自定义分辨率 (4K/2K/1080p/720p/480p/360p)
- 自定义帧率 (24/25/30/50/60 fps)
- 码率限制
- 自定义 FFmpeg 参数

✅ **增强的日志**
- FFprobe 读取视频元数据
- 实时压缩进度
- 详细的错误信息

### 系统要求

#### Android
- 最低 API Level: 24 (Android 7.0)
- Kotlin: 1.8.22+
- 支持架构: arm-v7a, arm64-v8a, x86, x86_64

#### iOS
- 最低 SDK: 14.0
- 支持架构: armv7, armv7s, arm64, arm64-simulator, x86_64

#### macOS
- 最低 SDK: 10.15
- 支持架构: arm64, x86_64

### 外部库支持

包含 25+ 外部库:
- **视频**: dav1d, kvazaar, libvpx, libwebp, x264, x265, xvidcore
- **音频**: lame, opus, speex, libvorbis, opencore-amr
- **字幕**: libass, freetype, fontconfig, fribidi
- **其他**: gnutls, libxml2, zimg, vid.stab

### 构建注意事项

1. **包大小**: Full-GPL 包体积较大 (~50MB),但功能完整
2. **编译时间**: 首次编译需要下载 FFmpeg 库,时间较长
3. **许可证**: GPL-3.0,如商业使用需注意许可证兼容性

### 测试状态

- ✅ Flutter analyze 通过
- ✅ 单元测试通过 (7/7)
- ⏳ Android 构建 (CI/CD 中)
- ⏳ iOS 构建 (CI/CD 中)

### 回退方案

如遇到问题,可回退到 `video_compress`:

```bash
git revert HEAD~3  # 回退最近3个提交
flutter pub get
```

### 参考文档

- 官方文档: https://pub.dev/packages/ffmpeg_kit_flutter_new
- FFmpeg 文档: https://ffmpeg.org/documentation.html
- GitHub: https://github.com/antonKharchenko1997/ffmpeg-kit

---

**日期**: 2025-10-29  
**版本**: 1.0.0+1
