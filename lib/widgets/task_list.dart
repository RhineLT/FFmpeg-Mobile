import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_manager.dart';
import '../models/video_task.dart';
import 'package:path/path.dart' as path;

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskManager>(
      builder: (context, taskManager, child) {
        final tasks = taskManager.tasks;

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无任务',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击下方 + 按钮添加视频',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(task: task);
          },
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final VideoTask task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: _buildStatusIcon(),
            title: Text(
              task.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                  ),
                ),
                if (task.status == VideoStatus.processing) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(task.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
                if (task.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '错误: ${task.errorMessage}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: _buildActions(context),
          ),
          if (task.status == VideoStatus.completed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '输出: ${path.basename(task.outputPath)}',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (task.status) {
      case VideoStatus.pending:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case VideoStatus.processing:
        icon = Icons.play_circle;
        color = Colors.blue;
        break;
      case VideoStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case VideoStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case VideoStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.orange;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _getStatusText() {
    switch (task.status) {
      case VideoStatus.pending:
        return '等待中';
      case VideoStatus.processing:
        return '压缩中';
      case VideoStatus.completed:
        return '已完成';
      case VideoStatus.failed:
        return '失败';
      case VideoStatus.cancelled:
        return '已取消';
    }
  }

  Color _getStatusColor() {
    switch (task.status) {
      case VideoStatus.pending:
        return Colors.grey;
      case VideoStatus.processing:
        return Colors.blue;
      case VideoStatus.completed:
        return Colors.green;
      case VideoStatus.failed:
        return Colors.red;
      case VideoStatus.cancelled:
        return Colors.orange;
    }
  }

  Widget _buildActions(BuildContext context) {
    final taskManager = context.read<TaskManager>();

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'retry':
            await taskManager.retryTask(task.id);
            break;
          case 'remove':
            await taskManager.removeTask(task.id);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (task.status == VideoStatus.failed || 
            task.status == VideoStatus.cancelled) {
          items.add(
            const PopupMenuItem(
              value: 'retry',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('重试'),
                ],
              ),
            ),
          );
        }

        items.add(
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('删除'),
              ],
            ),
          ),
        );

        return items;
      },
    );
  }
}
