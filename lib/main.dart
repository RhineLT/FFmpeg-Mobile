import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_manager.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  // Catch all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter Error: ${details.exception}',
      name: 'FFmpeg-Mobile',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    developer.log('App starting...', name: 'FFmpeg-Mobile');

    try {
      // Initialize services
      developer.log('Initializing LogService...', name: 'FFmpeg-Mobile');
      final logService = LogService();
      await logService.init();

      developer.log('Initializing StorageService...', name: 'FFmpeg-Mobile');
      final storageService = StorageService();
      
      developer.log('Initializing TaskManager...', name: 'FFmpeg-Mobile');
      final taskManager = TaskManager(
        logService: logService,
        storageService: storageService,
      );
      await taskManager.init();

      developer.log('Running app...', name: 'FFmpeg-Mobile');
      runApp(MyApp(
        logService: logService,
        taskManager: taskManager,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Fatal error during initialization: $e',
        name: 'FFmpeg-Mobile',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Show error screen
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
  }, (error, stackTrace) {
    developer.log(
      'Uncaught error: $error',
      name: 'FFmpeg-Mobile',
      error: error,
      stackTrace: stackTrace,
    );
  });
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
