import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_manager.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  runZonedGuarded(
    () {
      developer.log('App starting...', name: 'FFmpeg-Mobile');

      final logService = LogService();
      final storageService = StorageService();
      final taskManager = TaskManager(
        logService: logService,
        storageService: storageService,
      );

      developer.log('Running app...', name: 'FFmpeg-Mobile');
      runApp(
        MyApp(
          logService: logService,
          taskManager: taskManager,
          storageService: storageService,
        ),
      );
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught error: $error',
        name: 'FFmpeg-Mobile',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<void> _initializeAppInternal({
  required LogService logService,
  required StorageService storageService,
  required TaskManager taskManager,
}) async {
  try {
    developer.log('Initializing LogService...', name: 'FFmpeg-Mobile');
    await logService.init();
    developer.log('LogService initialized', name: 'FFmpeg-Mobile');

    developer.log('Initializing StorageService...', name: 'FFmpeg-Mobile');
    await storageService.init();
    developer.log('StorageService initialized', name: 'FFmpeg-Mobile');

    developer.log('Initializing TaskManager...', name: 'FFmpeg-Mobile');
    await taskManager.init();
    developer.log('TaskManager initialized', name: 'FFmpeg-Mobile');
  } catch (e, stackTrace) {
    developer.log(
      'Fatal error during initialization: $e',
      name: 'FFmpeg-Mobile',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  final LogService logService;
  final TaskManager taskManager;
  final StorageService storageService;

  const MyApp({
    super.key,
    required this.logService,
    required this.taskManager,
    required this.storageService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeAppInternal(
      logService: widget.logService,
      storageService: widget.storageService,
      taskManager: widget.taskManager,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.logService),
        ChangeNotifierProvider.value(value: widget.taskManager),
      ],
      child: MaterialApp(
        title: '视频压缩器',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _InitializationLoadingScreen();
            }

            if (snapshot.hasError) {
              return _InitializationErrorScreen(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
              );
            }

            return const HomeScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _InitializationLoadingScreen extends StatelessWidget {
  const _InitializationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 16),
              Text(
                '应用初始化中...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitializationErrorScreen extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;

  const _InitializationErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '错误信息:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    '${error ?? "未知错误"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '堆栈跟踪:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '${stackTrace ?? "无堆栈信息"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
