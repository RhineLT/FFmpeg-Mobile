# File Picker 问题修复说明

## 问题描述
应用在选择视频文件时出现 `MissingPluginException` 错误，提示 `file_picker` 插件的 `video` 方法未实现。

## 根本原因
`file_picker` 插件在 Android 上需要额外的 AndroidManifest.xml 配置，包括：
1. Intent 查询声明（用于文件选择器操作）
2. FileProvider 配置（用于安全地访问文件）

## 已完成的修复

### 1. 更新 AndroidManifest.xml
文件路径: `/workspaces/FFmpeg-Mobile/android/app/src/main/AndroidManifest.xml`

添加了以下配置：

#### a. Intent 查询声明（在 `<queries>` 标签内）
```xml
<!-- file_picker: Support for getting documents -->
<intent>
    <action android:name="android.intent.action.GET_CONTENT"/>
</intent>
<!-- file_picker: Support for opening documents -->
<intent>
    <action android:name="android.intent.action.OPEN_DOCUMENT"/>
</intent>
<!-- file_picker: Support for picking content -->
<intent>
    <action android:name="android.intent.action.PICK"/>
</intent>
```

#### b. FileProvider 配置（在 `<application>` 标签内）
```xml
<!-- file_picker: FileProvider for accessing files -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

### 2. 创建 file_paths.xml
文件路径: `/workspaces/FFmpeg-Mobile/android/app/src/main/res/xml/file_paths.xml`

这个文件定义了 FileProvider 可以访问的路径：
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="." />
    <external-files-path name="external_files" path="." />
    <cache-path name="cache" path="." />
    <external-cache-path name="external_cache" path="." />
    <files-path name="files" path="." />
</paths>
```

## 重新构建应用的步骤

由于当前开发环境没有完整的 Android SDK，请按以下步骤在本地机器上重新构建：

### 方案 1: 使用 Android Studio
1. 在 Android Studio 中打开项目
2. 连接 Android 设备
3. 点击 Run 按钮（绿色三角形）

### 方案 2: 使用命令行
```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建并安装 Debug APK
flutter build apk --debug
flutter install

# 或者直接运行
flutter run
```

### 方案 3: 构建 Release APK
```bash
flutter build apk --release
# 然后手动安装生成的 APK
# 位置: build/app/outputs/flutter-apk/app-release.apk
```

## 验证修复

重新安装应用后，执行以下操作验证修复：

1. 打开应用
2. 点击"选择视频"按钮
3. 文件选择器应该正常打开
4. 可以正常选择视频文件
5. 不应再出现 `MissingPluginException` 错误

## 技术说明

### 为什么需要这些配置？

1. **Intent 查询声明**: Android 11+ 引入了包可见性限制。应用需要显式声明它想要与哪些 Intent 交互。

2. **FileProvider**: Android 7.0+ 禁止应用通过 `file://` URI 在应用间共享文件。FileProvider 提供了安全的方式来共享文件 URI。

### 相关文档
- [file_picker 官方文档](https://pub.dev/packages/file_picker)
- [Android 包可见性](https://developer.android.com/training/package-visibility)
- [FileProvider 文档](https://developer.android.com/reference/androidx/core/content/FileProvider)

## 其他可能的问题

如果问题仍然存在，请检查：

1. **权限**: 确保应用有存储权限
2. **插件版本**: 当前使用 `file_picker: ^8.3.7`，可以尝试更新到最新版本
3. **Flutter 缓存**: 运行 `flutter clean` 清理缓存
4. **依赖冲突**: 运行 `flutter pub outdated` 检查依赖问题

## 更新日志

- **2025-10-30**: 修复 file_picker 插件的 Android 配置问题
