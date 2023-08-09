import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:deadline_manager/database.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier(ref);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TaskListNotifier(this._ref) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasks();
    state = tasks;
  }

  Future<void> addOrUpdateTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    if (task.id == null) {
      // 新しいタスクを追加
      final insertId = await db.insertTask(task);
      scheduleNotification(insertId, task.title, task.dueDate);
    } else {
      // 既存のタスクを更新
      await db.updateTask(task);
      cancelNotification(task.id);
      scheduleNotification(task.id, task.title, task.dueDate);
    }
    _loadTasks();
  }

  Future<void> deleteTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    await db.deleteTask(task);
    cancelNotification(task.id);
    _loadTasks();
  }

  Future<void> scheduleNotification(
      int? id, String title, DateTime dueDate) async {
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics =
        NotificationDetails(iOS: iOSPlatformChannelSpecifics);
    final tzDueDate = TZDateTime.from(dueDate, local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id!,
      DateFormat.yMMMEd('ja').add_jm().format(tzDueDate),
      title,
      tzDueDate,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> cancelNotification(int? id) async {
    await flutterLocalNotificationsPlugin.cancel(id!);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await db.updateTask(updatedTask);
    _loadTasks();
  }
}
