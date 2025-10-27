# 视频压缩器（Video Compressor）

Flutter 构建的双平台视频压缩器，现作为历史文档保存在 `docs/` 目录。应用支持批量选择系统视频、逐个以 H.265 CRF 28 进行压制，并持久化日志及任务信息。

## 功能特性

- ✅ 多选视频：支持一次性导入多个原始文件
- ✅ H.265 压缩：使用 FFmpeg Kit 执行 `libx265 -crf 28`
- ✅ 队列执行：串行处理，实时更新进度百分比
- ✅ 任务管理：暂停/恢复、重试失败、清除已完成
- ✅ 数据持久化：任务与日志落盘，应用重启后恢复

## 模块划分

```
lib/
├── main.dart                         # 应用入口
├── models/                           # 数据模型
│   ├── video_task.dart               # 视频任务定义
│   └── log_entry.dart                # 日志条目结构
├── providers/                        # 状态管理（Provider）
│   └── task_manager.dart             # 队列与状态机
├── services/                         # 功能服务
│   ├── video_compression_service.dart# FFmpeg 调度与进度回调
│   ├── storage_service.dart          # 本地存储抽象
│   └── log_service.dart              # 日志记录
├── screens/                          # UI 页面
│   ├── home_screen.dart              # 任务列表与控制台
│   └── logs_screen.dart              # 日志查看
└── widgets/                          # UI 组件
    ├── task_list.dart                # 任务列表组件
    └── stats_card.dart               # 统计面板
```

## 运行步骤

```bash
flutter pub get
flutter run              # 连接模拟器或真机
```

常用命令：

- `flutter analyze`：静态分析
- `flutter test`：运行单元测试
- `flutter build apk`：构建调试 APK

## FFmpeg 参数

```
-c:v libx265
-crf 28
-preset medium
-c:a aac
-b:a 128k
```

## 许可证

MIT
