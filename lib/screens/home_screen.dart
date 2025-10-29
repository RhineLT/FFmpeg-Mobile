import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_manager.dart';
import '../widgets/task_list.dart';
import '../widgets/stats_card.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import 'permission_diagnostic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFmpeg-Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: '权限诊断',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionDiagnosticScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '压缩设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: '查看日志',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: '设置输出目录',
            onPressed: () async {
              await context.read<TaskManager>().selectOutputDirectory();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final taskManager = context.read<TaskManager>();
              switch (value) {
                case 'clear_completed':
                  await taskManager.clearCompleted();
                  break;
                case 'clear_all':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认'),
                      content: const Text('确定要清除所有任务吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await taskManager.clearAll();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Text('清除已完成'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('清除所有'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats cards
          const StatsCard(),
          
          // Output directory
          Consumer<TaskManager>(
            builder: (context, taskManager, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '输出目录: ${taskManager.outputDirectory ?? "未设置"}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Task list
          const Expanded(
            child: TaskList(),
          ),
        ],
      ),
      floatingActionButton: Consumer<TaskManager>(
        builder: (context, taskManager, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Start/Pause button
              if (taskManager.pendingCount > 0)
                FloatingActionButton(
                  heroTag: 'process',
                  onPressed: taskManager.isProcessing
                      ? () async {
                          await taskManager.pauseProcessing();
                        }
                      : () async {
                          await taskManager.startProcessing();
                        },
                  backgroundColor: taskManager.isProcessing
                      ? Colors.orange
                      : Colors.green,
                  child: Icon(
                    taskManager.isProcessing ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              const SizedBox(height: 16),
              
              // Add videos button
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () async {
                  await taskManager.pickVideos();
                },
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
      ),
    );
  }
}
