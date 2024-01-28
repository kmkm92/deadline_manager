import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:deadline_manager/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // _loadTasks();
    sortTask();
  }

  Future<void> loadTasks() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasks();
    state = tasks;
  }

  Future<void> loadTasksSortAsc() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasksSortedAsc();
    state = tasks;
  }

  Future<void> loadTasksSortDesc() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllTasksSortedDesc();
    state = tasks;
  }

  Future<void> addOrUpdateTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    if (task.id == null) {
      // 新しいタスクを追加
      final insertId = await db.insertTask(task);
      if (task.shouldNotify) {
        scheduleNotification(insertId, task.title, task.dueDate);
      }
    } else {
      // 既存のタスクを更新
      await db.updateTask(task);
      cancelNotification(task.id);
      if (task.shouldNotify) {
        scheduleNotification(task.id, task.title, task.dueDate);
      }
    }
    // loadTasks();
    await sortTask();
  }

// 論理削除
  Future<void> deleteTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    final deletedTask = task.copyWith(isDeleted: true, shouldNotify: false);
    await db.updateTask(deletedTask);
    cancelNotification(task.id);
    await sortTask();
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
    final tzDueDate = TZDateTime.from(task.dueDate, local);
    final tzDateTimeNow = TZDateTime.from(DateTime.now(), local);
    // 通知ありのタスクをチェックしたとき
    if (task.shouldNotify && !task.isCompleted) {
      cancelNotification(task.id);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await db.updateTask(updatedTask);

      // 通知ありのタスクのチェック外すとき
    } else if (task.shouldNotify && task.isCompleted) {
      if (tzDueDate.isAfter(tzDateTimeNow)) {
        scheduleNotification(task.id, task.title, task.dueDate);
        final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
        await db.updateTask(updatedTask);
      } else {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          shouldNotify: !task.shouldNotify,
        );
        await db.updateTask(updatedTask);
      }
    } else {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await db.updateTask(updatedTask);
    }

    // loadTasks();
    await sortTask();
  }

  Future<void> sortTask() async {
    final prefs = await SharedPreferences.getInstance();
    final sort = prefs.getString('sort') ?? 'createTime';

    if (sort == 'createTime') {
      await loadTasks();
    } else if (sort == 'dueDateAsc') {
      await loadTasksSortAsc();
    } else if (sort == 'dueDateDesc') {
      await loadTasksSortDesc();
    }
  }

  Future<void> changeSortOrder(String sortOrder) async {
    final prefs = await SharedPreferences.getInstance();
    if (sortOrder == '期限日が早い順') {
      await loadTasksSortAsc();
      prefs.setString('sort', 'dueDateAsc');
    } else if (sortOrder == '期限日が遅い順') {
      prefs.setString('sort', 'dueDateDesc');
      await loadTasksSortDesc();
    } else if (sortOrder == '作成順') {
      prefs.setString('sort', 'createTime');
      await loadTasks();
    }
  }
}
