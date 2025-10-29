import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_manager.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('=== App Initialization Started ===');
    
    // Initialize services
    debugPrint('Step 1: Initializing LogService...');
    final logService = LogService();
    await logService.init();
    debugPrint('Step 1: LogService initialized ✓');

    debugPrint('Step 2: Initializing StorageService...');
    final storageService = StorageService();
    await storageService.init(); // 添加缺失的初始化调用
    debugPrint('Step 2: StorageService initialized ✓');
    
    debugPrint('Step 3: Initializing TaskManager...');
    final taskManager = TaskManager(
      logService: logService,
      storageService: storageService,
    );
    await taskManager.init();
    debugPrint('Step 3: TaskManager initialized ✓');

    debugPrint('Step 4: Starting app...');
    runApp(MyApp(
      logService: logService,
      taskManager: taskManager,
    ));
    debugPrint('=== App Started Successfully ===');
  } catch (e, stackTrace) {
    // 如果初始化失败，显示错误界面而不是白屏
    debugPrint('=== FATAL ERROR ===');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '错误: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final LogService logService;
  final TaskManager taskManager;

  const MyApp({
    super.key,
    required this.logService,
    required this.taskManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: logService),
        ChangeNotifierProvider.value(value: taskManager),
      ],
      child: MaterialApp(
        title: '视频压缩器',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
