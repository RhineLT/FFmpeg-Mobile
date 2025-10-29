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
    try {
      // Must initialize Flutter binding first
      WidgetsFlutterBinding.ensureInitialized();
      
      developer.log('App starting...', name: 'FFmpeg-Mobile');

      // Initialize services with proper error handling
      developer.log('Initializing LogService...', name: 'FFmpeg-Mobile');
      final logService = LogService();
      await logService.init();
      developer.log('LogService initialized', name: 'FFmpeg-Mobile');

      developer.log('Initializing StorageService...', name: 'FFmpeg-Mobile');
      final storageService = StorageService();
      await storageService.init();
      developer.log('StorageService initialized', name: 'FFmpeg-Mobile');
      
      developer.log('Creating TaskManager...', name: 'FFmpeg-Mobile');
      final taskManager = TaskManager(
        logService: logService,
        storageService: storageService,
      );
      
      developer.log('Initializing TaskManager...', name: 'FFmpeg-Mobile');
      await taskManager.init();
      developer.log('TaskManager initialized', name: 'FFmpeg-Mobile');

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
      
      // Show error screen with full error details
      runApp(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      '应用初始化失败',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '错误信息:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '堆栈跟踪:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            '$stackTrace',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
