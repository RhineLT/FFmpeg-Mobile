import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_manager.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskManager>(
      builder: (context, taskManager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.schedule,
                label: '等待中',
                value: taskManager.pendingCount.toString(),
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: '已完成',
                value: taskManager.completedCount.toString(),
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.error,
                label: '失败',
                value: taskManager.failedCount.toString(),
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.video_library,
                label: '总计',
                value: taskManager.tasks.length.toString(),
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
