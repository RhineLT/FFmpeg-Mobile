# FFmpeg-Mobile 问题修复汇总

## 修复日期
2025-10-30

## 已修复的问题

### 问题: file_picker 插件 MissingPluginException

#### 错误信息
```
Error: MissingPluginException(No implementation found for method video on channel miguelruivo.flutter.plugins.filepicker)
```

#### 原因分析
`file_picker` 插件在 Android 平台需要在 AndroidManifest.xml 中进行额外配置，包括：
1. Intent 查询声明（Android 11+ 包可见性要求）
2. FileProvider 配置（Android 7.0+ 文件共享安全要求）

#### 修复内容

##### 1. 修改 android/app/src/main/AndroidManifest.xml

**添加的 Intent 查询声明:**
```xml
<queries>
    <!-- 现有的 PROCESS_TEXT intent -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    
    <!-- 新增: file_picker 所需的 intent -->
    <intent>
        <action android:name="android.intent.action.GET_CONTENT"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.OPEN_DOCUMENT"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.PICK"/>
    </intent>
</queries>
```

**添加的 FileProvider 配置:**
```xml
<application>
    <!-- 现有配置 -->
    ...
    
    <!-- 新增: FileProvider for file_picker -->
    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.fileprovider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
    </provider>
</application>
```

##### 2. 创建 android/app/src/main/res/xml/file_paths.xml

新建文件，内容如下：
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

## 如何重新构建和测试

### 快速方法（推荐）

使用提供的构建脚本：

```bash
# 构建 Debug 版本
./rebuild.sh

# 或构建 Release 版本
./rebuild.sh release
```

### 手动方法

```bash
# 1. 清理项目
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建并安装
flutter build apk --debug
flutter install

# 或者直接运行
flutter run
```

## 测试步骤

重新安装应用后，按以下步骤测试：

1. ✅ 启动应用（应该正常启动）
2. ✅ 点击"选择视频"按钮
3. ✅ 系统文件选择器应该打开
4. ✅ 可以浏览和选择视频文件
5. ✅ 选择后应该添加到任务列表
6. ✅ 不应再出现 MissingPluginException 错误

## 文件变更清单

| 文件路径 | 操作 | 说明 |
|---------|------|------|
| `android/app/src/main/AndroidManifest.xml` | 修改 | 添加 Intent 查询和 FileProvider 配置 |
| `android/app/src/main/res/xml/file_paths.xml` | 新建 | FileProvider 路径配置 |
| `rebuild.sh` | 新建 | 自动化构建脚本 |
| `FILE_PICKER_FIX.md` | 新建 | file_picker 修复详细说明 |
| `FIXES_SUMMARY.md` | 新建 | 本文档 |

## 技术背景

### Android 包可见性（Package Visibility）

从 Android 11 (API 30) 开始，Android 引入了包可见性限制。应用默认无法查询或与其他应用交互，除非：
1. 在 AndroidManifest.xml 中声明 `<queries>` 标签
2. 声明需要交互的 Intent 或包名

参考: https://developer.android.com/training/package-visibility

### FileProvider

从 Android 7.0 (API 24) 开始，Android 禁止通过 `file://` URI 在应用间共享文件。必须使用 FileProvider 生成 `content://` URI。

FileProvider 提供：
- 安全的文件共享机制
- 临时访问权限授予
- 细粒度的路径访问控制

参考: https://developer.android.com/reference/androidx/core/content/FileProvider

## 相关依赖版本

当前使用的相关依赖版本：

```yaml
dependencies:
  file_picker: ^8.3.7
  path_provider: ^2.1.5
  path: ^1.9.0
```

## 可能的后续问题

如果仍然遇到问题，请检查：

### 1. 运行时权限
确保应用有必要的存储权限：
- Android 13+: `READ_MEDIA_VIDEO`
- Android 6-12: `READ_EXTERNAL_STORAGE`
- Android 11+: 可能需要 `MANAGE_EXTERNAL_STORAGE` (用于访问外部存储)

当前 AndroidManifest.xml 已包含这些权限声明。

### 2. 插件版本兼容性
如果问题持续，可以尝试：
```bash
# 查看可用更新
flutter pub outdated

# 更新 file_picker 到最新版本
# 编辑 pubspec.yaml，然后运行
flutter pub upgrade file_picker
```

### 3. Flutter 缓存问题
完全清理缓存：
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### 4. 依赖冲突
检查依赖冲突：
```bash
flutter pub deps
```

## 联系和支持

如果遇到其他问题：
1. 查看 Flutter 日志: `flutter logs`
2. 查看 Android logcat: `adb logcat`
3. 检查 file_picker 官方文档: https://pub.dev/packages/file_picker
4. 提交 Issue 到项目仓库

## 更新历史

- **2025-10-30**: 修复 file_picker 插件 Android 配置问题
  - 添加 Intent 查询声明
  - 配置 FileProvider
  - 创建构建脚本和文档
