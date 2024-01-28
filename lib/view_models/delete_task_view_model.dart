import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:deadline_manager/database.dart';

final deleteTaskListProvider =
    StateNotifierProvider<DeleteTaskListNotifier, List<Task>>((ref) {
  return DeleteTaskListNotifier(ref);
});

class DeleteTaskListNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  DeleteTaskListNotifier(this._ref) : super([]) {
    loadDeleteTasks();
  }

  Future<void> loadDeleteTasks() async {
    final db = await _ref.read(provideDatabase.future);
    final tasks = await db.getAllDeleteTasks();
    state = tasks;
  }

  // 物理削除
  Future<void> deleteTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    await db.deleteTask(task);
    // _loadTasks();
    await loadDeleteTasks();
  }

  // 復元
  Future<void> restoreTask(Task task) async {
    final db = await _ref.read(provideDatabase.future);
    task = Task(
        id: task.id,
        title: task.title,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        isDeleted: false,
        shouldNotify: task.shouldNotify);
    await db.updateTask(task);
    await loadDeleteTasks();
  }
}
