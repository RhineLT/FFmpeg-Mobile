import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除日志',
            onPressed: () async {
              final logService = context.read<LogService>();
              
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认'),
                  content: const Text('确定要清除所有日志吗？'),
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
              if (confirmed == true && context.mounted) {
                await logService.clearLogs();
              }
            },
          ),
        ],
      ),
      body: Consumer<LogService>(
        builder: (context, logService, child) {
          final logs = logService.logs;
          
          if (logs.isEmpty) {
            return const Center(
              child: Text('暂无日志'),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              Color logColor;
              IconData logIcon;

              switch (log.level) {
                case 'ERROR':
                  logColor = Colors.red;
                  logIcon = Icons.error;
                  break;
                case 'WARNING':
                  logColor = Colors.orange;
                  logIcon = Icons.warning;
                  break;
                case 'INFO':
                  logColor = Colors.blue;
                  logIcon = Icons.info;
                  break;
                case 'DEBUG':
                  logColor = Colors.grey;
                  logIcon = Icons.bug_report;
                  break;
                default:
                  logColor = Colors.black;
                  logIcon = Icons.article;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(logIcon, color: logColor, size: 20),
                  title: Text(
                    log.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: logColor,
                    ),
                  ),
                  subtitle: Text(
                    log.toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                  dense: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
