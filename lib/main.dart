import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_manager.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final logService = LogService();
  await logService.init();

  final storageService = StorageService();
  
  final taskManager = TaskManager(
    logService: logService,
    storageService: storageService,
  );
  await taskManager.init();

  runApp(MyApp(
    logService: logService,
    taskManager: taskManager,
  ));
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
