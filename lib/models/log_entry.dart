class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? taskId;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.taskId,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'message': message,
      'taskId': taskId,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'],
      message: json['message'],
      taskId: json['taskId'],
    );
  }

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] [$level] $message';
  }
}
