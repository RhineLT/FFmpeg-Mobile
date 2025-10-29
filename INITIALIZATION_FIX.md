# Android 应用初始化失败问题修复

## 问题描述

用户报告 Android 应用启动时出现以下错误：

```
应用初始化失败
错误: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.shared_preferences_android.SharedPreferencesApi.getAll"., null, null)
```

## 根本原因分析

### 1. SharedPreferences 初始化时机问题
- `LogService` 和 `StorageService` 都使用 `SharedPreferences`
- 这两个服务在每次调用时都会执行 `SharedPreferences.getInstance()`
- 在应用初始化早期，Flutter Engine 可能还没有完全准备好处理 platform channels
- 导致 channel 连接失败

### 2. 缺少明确的初始化流程
- `StorageService` 没有 `init()` 方法
- `LogService` 的 `init()` 方法只是加载日志，没有初始化 SharedPreferences
- 服务之间的初始化顺序不明确

### 3. 错误处理不足
- 没有捕获 SharedPreferences 初始化失败的情况
- 错误信息不够详细，难以定位问题

## 解决方案

### 1. 重构 StorageService

**添加明确的初始化方法**:
```dart
class StorageService {
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      debugPrint('StorageService: Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('StorageService: SharedPreferences initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('StorageService: Failed to initialize SharedPreferences: $e');
      debugPrint('StorageService: StackTrace: $stackTrace');
      rethrow;
    }
  }
}
```

**使用缓存的实例**:
- 在 `init()` 中获取一次 `SharedPreferences.getInstance()`
- 将实例保存到 `_prefs` 字段
- 后续所有操作都使用缓存的实例，避免重复调用

### 2. 重构 LogService

**采用相同的初始化模式**:
```dart
class LogService extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      debugPrint('LogService: Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('LogService: SharedPreferences initialized');
      
      await _loadLogs();
      debugPrint('LogService: Loaded ${_logs.length} log entries');
    } catch (e, stackTrace) {
      debugPrint('LogService: Failed to initialize: $e');
      // 日志服务不是关键功能，允许应用继续运行
      _initialized = true;
    }
  }
}
```

### 3. 优化 main.dart 初始化流程

**确保正确的初始化顺序**:
```dart
void main() async {
  runZonedGuarded(() async {
    try {
      // 1. 首先初始化 Flutter binding
      WidgetsFlutterBinding.ensureInitialized();
      
      // 2. 初始化 LogService
      final logService = LogService();
      await logService.init();
      
      // 3. 初始化 StorageService
      final storageService = StorageService();
      await storageService.init();
      
      // 4. 创建并初始化 TaskManager
      final taskManager = TaskManager(
        logService: logService,
        storageService: storageService,
      );
      await taskManager.init();
      
      // 5. 启动应用
      runApp(MyApp(
        logService: logService,
        taskManager: taskManager,
      ));
    } catch (e, stackTrace) {
      // 显示详细的错误信息
      runApp(ErrorApp(error: e, stackTrace: stackTrace));
    }
  }, (error, stack) {
    // 处理未捕获的异步错误
  });
}
```

### 4. 增强错误处理和日志

**添加详细的调试日志**:
- 每个初始化步骤都输出日志
- 使用 `developer.log()` 确保日志能在 logcat 中看到
- 错误时显示完整的堆栈跟踪

**改进错误显示界面**:
- 显示红色错误图标
- 显示错误消息
- 显示完整的堆栈跟踪（可滚动）
- 使用 SafeArea 避免显示问题

## 修复后的初始化流程图

```
main()
  ↓
runZonedGuarded() - 捕获所有错误
  ↓
WidgetsFlutterBinding.ensureInitialized() - Flutter 引擎初始化
  ↓
LogService.init()
  ├─ SharedPreferences.getInstance() (一次性)
  └─ 加载历史日志
  ↓
StorageService.init()
  └─ SharedPreferences.getInstance() (一次性)
  ↓
TaskManager(logService, storageService)
  ↓
TaskManager.init()
  ├─ 加载已保存的任务
  ├─ 加载压缩设置
  ├─ 加载输出目录
  └─ 重置处理中的任务
  ↓
runApp(MyApp)
```

## 关键改进点

### 1. 单例模式
- 每个服务只初始化一次 SharedPreferences
- 使用 `_initialized` 标志防止重复初始化

### 2. 显式初始化
- 所有服务都有明确的 `init()` 方法
- 初始化顺序清晰可控

### 3. 错误隔离
- LogService 初始化失败不会导致应用崩溃
- StorageService 初始化失败会抛出错误（因为是关键服务）

### 4. 调试友好
- 每个步骤都有日志输出
- 错误信息详细且可追踪

## 验证清单

- [x] `flutter analyze` 通过
- [ ] Android debug 构建成功
- [ ] Android release 构建成功
- [ ] 应用能正常启动
- [ ] SharedPreferences 能正常读写
- [ ] 任务列表能正常加载和保存
- [ ] 日志功能正常工作
- [ ] 压缩设置能正常保存和加载

## 下一步测试

1. 构建 APK 并在设备上测试
2. 使用 `adb logcat` 查看详细的初始化日志
3. 验证所有功能正常工作
4. 推送到 CI/CD 进行自动化测试
