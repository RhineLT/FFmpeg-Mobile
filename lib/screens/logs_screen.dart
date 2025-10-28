import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final Set<String> _selectedLevels = {'ERROR', 'WARNING', 'INFO', 'DEBUG'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选日志等级',
            onSelected: (level) {
              setState(() {
                if (_selectedLevels.contains(level)) {
                  _selectedLevels.remove(level);
                } else {
                  _selectedLevels.add(level);
                }
              });
            },
            itemBuilder: (context) => [
              _buildFilterMenuItem('ERROR', Icons.error, Colors.red),
              _buildFilterMenuItem('WARNING', Icons.warning, Colors.orange),
              _buildFilterMenuItem('INFO', Icons.info, Colors.blue),
              _buildFilterMenuItem('DEBUG', Icons.bug_report, Colors.grey),
            ],
          ),
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
          final allLogs = logService.logs;
          final filteredLogs = allLogs.where((log) => _selectedLevels.contains(log.level)).toList();
          
          if (filteredLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    allLogs.isEmpty ? '暂无日志' : '没有符合筛选条件的日志',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_selectedLevels.length < 4)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '已筛选: ${_selectedLevels.join(", ")} (显示 ${filteredLogs.length}/${allLogs.length} 条)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedLevels.addAll(['ERROR', 'WARNING', 'INFO', 'DEBUG']);
                          });
                        },
                        child: const Text('显示全部', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String level, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: level,
      child: Row(
        children: [
          Icon(
            _selectedLevels.contains(level) ? Icons.check_box : Icons.check_box_outline_blank,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(level),
        ],
      ),
    );
  }
}
