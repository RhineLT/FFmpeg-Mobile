# 更新日志 (Changelog)

## v1.1.0 (2025-10-28)

### 🎉 重大优化

#### 核心功能修复
- **修复批量压缩错误**：解决了处理 2 个以上视频时出现的 "Bad state: Stream has already been listened to" 错误
- **进度订阅管理**：正确实现 subscribe/unsubscribe 机制，每次压缩前取消旧订阅
- **稳定性提升**：现在可以可靠地批量处理任意数量的视频

#### 输出目录优化
- **Android 公共目录**：输出到 `/storage/emulated/0/Movies/FFmpeg-Mobile/`
- **用户友好**：压缩后的视频可直接在系统文件管理器中访问
- **智能降级**：如果无法创建公共目录，自动降级到应用存储目录
- **iOS 优化**：使用文档目录，便于通过文件 App 访问

#### 品牌更新
- **应用名称**：统一为 "FFmpeg-Mobile"
  - Android: Manifest 和启动器
  - iOS: Info.plist 和显示名称
  - UI: 应用标题栏
- **官方图标**：使用 FFmpeg 官方 logo
  - 支持 Android 自适应图标
  - iOS 全尺寸图标集
  - 黑色背景，专业外观

### 📦 构建信息

#### CI/CD 结果
- ✅ **iOS Release IPA**: 2m34s
- ✅ **Android Debug APK**: 5m23s (141MB)
- ✅ **Android Release APK**: 已生成
- ✅ **代码质量检查**: 42s，无问题
- ✅ **单元测试**: 7/7 通过

#### 本地构建
- ✅ Flutter analyze: 无问题
- ✅ Flutter test: 全部通过
- ✅ Gradle build: 成功 (3m49s)

---

## v1.0.0 (2025-10-27)

### 🚀 初始版本

#### 核心功能
- 批量视频压缩支持
- H.265 (HEVC) 编码
- 实时进度跟踪
- 完整的日志系统
- 任务状态持久化
- 断点续传支持

#### 技术架构
- Flutter 3.35.7 框架
- Provider 状态管理
- video_compress 压缩库
- SharedPreferences 存储
- Material Design UI

#### 平台支持
- ✅ Android (API 21+)
- ✅ iOS (10.0+)
- 🔄 自动化 CI/CD (GitHub Actions)

---

## 已知问题

### 已修复
- ~~批量压缩时第二个视频失败~~ (v1.1.0 修复)
- ~~输出目录不易访问~~ (v1.1.0 修复)

### 计划改进
- [ ] 支持更多压缩参数自定义
- [ ] 添加压缩预览功能
- [ ] 支持更多输出格式
- [ ] 添加批量操作优化选项
- [ ] 改进大文件处理性能

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

详见 [CONTRIBUTING.md](CONTRIBUTING.md)

---

**注意**: 本项目使用 `video_compress` 库替代已废弃的 FFmpeg Kit。
